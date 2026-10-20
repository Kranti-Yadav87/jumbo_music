import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/services/music_api_service.dart';
import 'package:jumbo_music/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (MethodCall call) async {
            if (call.method == 'init') {
              final id = (call.arguments as Map?)?['id'] as String?;
              if (id != null) {
                TestDefaultBinaryMessengerBinding
                    .instance
                    .defaultBinaryMessenger
                    .setMockMethodCallHandler(
                      MethodChannel('com.ryanheise.just_audio.methods.$id'),
                      (MethodCall instanceCall) async {
                        if (instanceCall.method == 'load') {
                          final eventData = const StandardMethodCodec()
                              .encodeSuccessEnvelope({
                                'processingState':
                                    3, // ProcessingStateMessage.ready
                                'updateTime':
                                    DateTime.now().millisecondsSinceEpoch,
                                'updatePosition': 0,
                                'bufferedPosition': 0,
                                'duration': 180000000,
                                'currentIndex':
                                    (instanceCall.arguments
                                        as Map?)?['initialIndex'] ??
                                    0,
                                'androidAudioSessionId': 1,
                              });
                          TestDefaultBinaryMessengerBinding
                              .instance
                              .defaultBinaryMessenger
                              .handlePlatformMessage(
                                'com.ryanheise.just_audio.events.$id',
                                eventData,
                                (ByteData? data) {},
                              );
                          return {'duration': 180000000};
                        }
                        if (instanceCall.method ==
                            'androidEqualizerGetParameters') {
                          return {
                            'minDecibels': -15.0,
                            'maxDecibels': 15.0,
                            'bands': [],
                          };
                        }
                        return {};
                      },
                    );
              }
              return {'id': id ?? 'test_player_1'};
            }
            if (call.method == 'load') {
              return {'duration': 180000000};
            }
            return {};
          },
        );
  });

  setUp(() {
    DatabaseService.instance.resetForTesting();
    MusicPlayerManager().resetStateForTesting();
  });

  group('Player Queue Progression & Single-Song Loop Prevention Tests', () {
    test(
      'playSong with newQueue preserves all caller-provided tracks without era purging',
      () async {
        final manager = MusicPlayerManager();
        final songs = List.generate(
          15,
          (i) => Song(
            id: 'test_song_$i',
            title: 'Track Title $i',
            artist: 'Artist $i',
            album: 'Album $i',
            coverUrl: 'https://example.com/cover$i.jpg',
            audioUrl: 'https://example.com/audio$i.mp3',
            duration: const Duration(seconds: 180),
          ),
        );

        await manager.playSong(songs[0], newQueue: songs);

        // Verify the queue has all 15 songs and hasn't been stripped
        expect(manager.queue.length, equals(15));
        expect(manager.currentSong?.id, equals(songs[0].id));

        // Skipping to another track index should preserve the full queue
        await manager.skipToQueueIndex(5);
        expect(manager.queue.length, equals(15));
        expect(manager.currentSong?.id, equals(songs[5].id));
      },
    );

    test(
      'playSongFromSearch populates immediate queue with searchResults',
      () async {
        final manager = MusicPlayerManager();
        final searchResults = List.generate(
          12,
          (i) => Song(
            id: 'search_result_$i',
            title: 'Tum Hi Ho $i',
            artist: 'Arijit Singh',
            album: 'Aashiqui 2',
            coverUrl: 'https://example.com/cover_search_$i.jpg',
            audioUrl: 'https://example.com/audio_search_$i.mp3',
            duration: const Duration(seconds: 240),
          ),
        );

        await manager.playSongFromSearch(
          searchResults.first,
          searchResults: searchResults,
        );

        // Queue must contain multiple search result tracks immediately
        expect(manager.queue.length, greaterThanOrEqualTo(10));
        expect(manager.currentSong?.id, equals(searchResults.first.id));
      },
    );

    test(
      'next() on a single song queue appends distinct fallback track and advances',
      () async {
        final otherSong = Song(
          id: 'library_song_2',
          title: 'Library Track 2',
          artist: 'Other Artist',
          album: 'Other Album',
          coverUrl: 'https://example.com/cover_other.jpg',
          audioUrl: 'https://example.com/audio_other.mp3',
          duration: const Duration(seconds: 210),
        );

        final manager = MusicPlayerManager();
        manager.setMockState(allSongs: [otherSong]);

        final seedSong = Song(
          id: 'isolated_song_1',
          title: 'Only Track',
          artist: 'Solo Artist',
          album: 'Solo Album',
          coverUrl: 'https://example.com/cover_solo.jpg',
          audioUrl: 'https://example.com/audio_solo.mp3',
          duration: const Duration(seconds: 200),
        );

        // Play isolated song as single song
        await manager.playSong(seedSong, newQueue: [seedSong]);
        expect(manager.queue.length, equals(1));
        expect(manager.currentSong?.id, equals(seedSong.id));

        // Call next()
        await manager.next();

        // Ensure that playback did NOT re-play the exact same track
        expect(manager.currentSong?.id, isNot(equals(seedSong.id)));
        expect(manager.queue.length, greaterThan(1));
      },
    );

    test(
      'next() on a single song queue with zero in-memory candidates invokes live search fallback',
      () async {
        final manager = MusicPlayerManager();
        // Completely empty all candidate pools
        manager.setMockState(allSongs: []);

        final liveFallbackSong = Song(
          id: 'live_fetch_song_99',
          title: 'Live Hindi Hit 99',
          artist: 'Arijit Singh',
          album: 'Live Album',
          coverUrl: 'https://example.com/cover_live.jpg',
          audioUrl: 'https://example.com/audio_live.mp3',
          duration: const Duration(seconds: 220),
        );

        MusicApiService.mockSearchLiveSongs =
            (String query, {int limit = 30}) async {
              return [liveFallbackSong];
            };

        final singleSong = Song(
          id: 'single_track_88',
          title: 'Single Dil Track',
          artist: 'Arijit Singh',
          album: 'Single Album',
          coverUrl: 'https://example.com/cover_single.jpg',
          audioUrl: 'https://example.com/audio_single.mp3',
          duration: const Duration(seconds: 190),
        );

        await manager.playSong(singleSong, newQueue: [singleSong]);
        expect(manager.queue.length, equals(1));
        expect(manager.currentSong?.id, equals(singleSong.id));

        await manager.next();

        // Verify that next() fetched the live song and advanced to it
        expect(manager.currentSong?.id, equals(liveFallbackSong.id));
        expect(manager.currentSong?.id, isNot(equals(singleSong.id)));

        MusicApiService.mockSearchLiveSongs = null;
      },
    );

    test(
      'skipToQueueIndex(0) on a 1-song queue delegates to next() and never loops',
      () async {
        final manager = MusicPlayerManager();
        if (manager.autoplay) manager.toggleAutoplay();
        manager.setMockState(allSongs: []);

        final nextTrack = Song(
          id: 'next_track_77',
          title: 'Next Track 77',
          artist: 'Live Artist',
          album: 'Next Album',
          coverUrl: 'https://example.com/cover77.jpg',
          audioUrl: 'https://example.com/audio77.mp3',
          duration: const Duration(seconds: 200),
        );

        MusicApiService.mockSearchLiveSongs =
            (String query, {int limit = 30}) async {
              return [nextTrack];
            };

        final isolatedSong = Song(
          id: 'isolated_77',
          title: 'Isolated Track',
          artist: 'Live Artist',
          album: 'Next Album',
          coverUrl: 'https://example.com/cover_iso.jpg',
          audioUrl: 'https://example.com/audio_iso.mp3',
          duration: const Duration(seconds: 200),
        );

        await manager.playSong(isolatedSong, newQueue: [isolatedSong]);
        expect(manager.queue.length, equals(1));

        // Attempt to skip to index 0 on 1-song queue
        await manager.skipToQueueIndex(0);

        // Verify it did not just replay isolatedSong
        expect(manager.currentSong?.id, equals(nextTrack.id));

        MusicApiService.mockSearchLiveSongs = null;
      },
    );

    test(
      'next() skips alternate release with different ID but same song title and plays distinct song',
      () async {
        final manager = MusicPlayerManager();
        manager.setMockState(allSongs: []);

        final song1 = Song(
          id: 'tum_hi_ho_id_1',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          coverUrl: 'https://example.com/cover1.jpg',
          audioUrl: 'https://example.com/audio1.mp3',
          duration: const Duration(seconds: 240),
        );

        final song1Alternate = Song(
          id: 'tum_hi_ho_id_2',
          title: 'Tum Hi Ho (From "Aashiqui 2")',
          artist: 'Arijit Singh',
          album: 'Arijit Singh Greatest Hits',
          coverUrl: 'https://example.com/cover2.jpg',
          audioUrl: 'https://example.com/audio2.mp3',
          duration: const Duration(seconds: 240),
        );

        final distinctSong = Song(
          id: 'channa_mereya_id_3',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          album: 'Ae Dil Hai Mushkil',
          coverUrl: 'https://example.com/cover3.jpg',
          audioUrl: 'https://example.com/audio3.mp3',
          duration: const Duration(seconds: 260),
        );

        // Queue has song1, followed by its alternate compilation version, followed by distinctSong
        await manager.playSong(
          song1,
          newQueue: [song1, song1Alternate, distinctSong],
        );
        expect(manager.currentSong?.id, equals(song1.id));

        // Call next()
        await manager.next();

        // Must NOT play song1Alternate (same canonical song!), must advance to distinctSong
        expect(manager.currentSong?.id, equals(distinctSong.id));
        expect(manager.currentSong?.title, equals('Channa Mereya'));
      },
    );

    test(
      'next() and skipToQueueIndex() switch currentSong and audio URL synchronously to the next track',
      () async {
        final manager = MusicPlayerManager();

        final firstTrack = Song(
          id: 'track_1',
          title: 'Pehle Bhi Main',
          artist: 'Vishal Mishra',
          album: 'Animal',
          coverUrl: 'https://example.com/animal.jpg',
          audioUrl: 'https://example.com/animal.mp3',
          duration: const Duration(seconds: 240),
        );

        final secondTrack = Song(
          id: 'track_2',
          title: 'Satranga',
          artist: 'Arijit Singh',
          album: 'Animal',
          coverUrl: 'https://example.com/satranga.jpg',
          audioUrl: 'https://example.com/satranga.mp3',
          duration: const Duration(seconds: 260),
        );

        await manager.playSong(firstTrack, newQueue: [firstTrack, secondTrack]);
        expect(manager.currentSong?.id, equals('track_1'));
        expect(manager.currentSong?.title, equals('Pehle Bhi Main'));
        expect(
          manager.currentSong?.audioUrl,
          equals('https://example.com/animal.mp3'),
        );
        expect(manager.currentIndex, equals(0));

        // Trigger next()
        await manager.next();

        // Verify that currentSong, title, audioUrl, and currentIndex ALL point to the next track
        expect(manager.currentSong?.id, equals('track_2'));
        expect(manager.currentSong?.title, equals('Satranga'));
        expect(
          manager.currentSong?.audioUrl,
          equals('https://example.com/satranga.mp3'),
        );
        expect(manager.currentIndex, equals(1));

        // Verify queue is completely preserved
        expect(manager.queue.length, equals(2));
        expect(manager.queue[0].id, equals('track_1'));
        expect(manager.queue[1].id, equals('track_2'));
      },
    );

    test(
      'explicit next() at end of queue wraps to first distinct track in queue',
      () async {
        final manager = MusicPlayerManager();
        final song1 = Song(
          id: 'wrap_track_1',
          title: 'Song One',
          artist: 'Artist One',
          album: 'Album One',
          coverUrl: 'https://example.com/cover1.jpg',
          audioUrl: 'https://example.com/audio1.mp3',
          duration: const Duration(seconds: 200),
        );
        final song2 = Song(
          id: 'wrap_track_2',
          title: 'Song Two',
          artist: 'Artist Two',
          album: 'Album Two',
          coverUrl: 'https://example.com/cover2.jpg',
          audioUrl: 'https://example.com/audio2.mp3',
          duration: const Duration(seconds: 210),
        );

        await manager.playSong(song2, newQueue: [song1, song2]);
        expect(manager.currentIndex, equals(1));
        expect(manager.currentSong?.id, equals(song2.id));

        // User clicks next on player UI (fromCompletion: false)
        await manager.next(fromCompletion: false);

        // Should wrap around to song1
        expect(manager.currentIndex, equals(0));
        expect(manager.currentSong?.id, equals(song1.id));
      },
    );

    test(
      'playSong upgrades 30s preview or short duration track to full-length live audio',
      () async {
        final manager = MusicPlayerManager();
        manager.setMockState(allSongs: []);

        final shortPreviewSong = Song(
          id: 'preview_apple_1',
          title: 'Kesariya (From "Brahmastra")',
          artist: 'Arijit Singh, Pritam',
          album: 'Brahmastra',
          coverUrl: 'https://example.com/kesariya.jpg',
          audioUrl: 'https://audio-ssl.itunes.apple.com/preview.m4a',
          duration: const Duration(seconds: 30),
        );

        final fullLengthSong = Song(
          id: 'full_length_saavn_1',
          title: 'Kesariya',
          artist: 'Arijit Singh',
          album: 'Brahmastra',
          coverUrl: 'https://example.com/kesariya_saavn.jpg',
          audioUrl: 'https://aac.saavncdn.com/kesariya_320.mp4',
          duration: const Duration(seconds: 268),
        );

        MusicApiService.mockSearchLiveSongs =
            (String query, {int limit = 30}) async {
              return [fullLengthSong];
            };

        await manager.playSong(shortPreviewSong, newQueue: [shortPreviewSong]);

        // Audio URL and duration should be upgraded from fullLengthSong
        expect(manager.currentSong?.audioUrl, equals(fullLengthSong.audioUrl));
        expect(
          manager.currentSong?.duration.inSeconds,
          greaterThanOrEqualTo(90),
        );

        MusicApiService.mockSearchLiveSongs = null;
      },
    );

    test(
      'Zero song repetition: MusicPlayerManager queue deduplicates title variants and never has duplicate songs',
      () async {
        final manager = MusicPlayerManager();
        manager.setMockState(allSongs: []);

        final songA = Song(
          id: 'tum_hi_ho_clean',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          coverUrl: 'https://example.com/cover1.jpg',
          audioUrl: 'https://example.com/audio1.mp3',
          duration: const Duration(seconds: 260),
        );

        final songAVariant1 = Song(
          id: 'tum_hi_ho_movie',
          title: 'Tum Hi Ho (From "Aashiqui 2")',
          artist: 'Arijit Singh, Mithoon',
          album: 'Aashiqui 2',
          coverUrl: 'https://example.com/cover2.jpg',
          audioUrl: 'https://example.com/audio2.mp3',
          duration: const Duration(seconds: 260),
        );

        final songAVariant2 = Song(
          id: 'tum_hi_ho_remaster',
          title: 'Tum Hi Ho [Remastered]',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          coverUrl: 'https://example.com/cover3.jpg',
          audioUrl: 'https://example.com/audio3.mp3',
          duration: const Duration(seconds: 260),
        );

        final songB = Song(
          id: 'channa_mereya_1',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          album: 'Ae Dil Hai Mushkil',
          coverUrl: 'https://example.com/cover4.jpg',
          audioUrl: 'https://example.com/audio4.mp3',
          duration: const Duration(seconds: 289),
        );

        // Play with a queue containing duplicate variations of the same song
        await manager.playSong(
          songA,
          newQueue: [songA, songAVariant1, songAVariant2, songB],
        );

        // Assert queue has exactly 2 songs (Tum Hi Ho and Channa Mereya), NO duplicates
        expect(manager.queue.length, equals(2));
        final seenKeys = <String>{};
        for (final s in manager.queue) {
          final key = SongParserUtils.songDeduplicationKey(s);
          expect(
            seenKeys.contains(key),
            isFalse,
            reason: 'Track $key appeared more than once in player queue!',
          );
          seenKeys.add(key);
        }
      },
    );

    test(
      'Zero automatic playlist creation: Playing songs does not generate Radio/Mix playlists in manager.playlists',
      () async {
        final manager = MusicPlayerManager();
        manager.setMockState(allSongs: []);

        // Verify playlists starts empty if no custom playlists were created
        expect(manager.playlists.isEmpty, isTrue);

        const songAlka = Song(
          id: 'alka_test_1',
          title: 'Pardesi Pardesi',
          artist: 'Alka Yagnik, Udit Narayan',
          album: 'Raja Hindustani',
          duration: Duration(seconds: 240),
          audioUrl: 'https://example.com/alka.mp3',
          coverUrl: '',
          genre: 'Bollywood',
        );

        const songJeet = Song(
          id: 'jeet_test_1',
          title: 'Chalo Ishq Ladaaye',
          artist: 'Jeet-Pritam',
          album: 'Chalo Ishq Ladaaye',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/jeet.mp3',
          coverUrl: '',
          genre: 'Bollywood',
        );

        await manager.playSong(songAlka, newQueue: [songAlka, songJeet]);
        await manager.playSong(songJeet);

        // Verify that NO auto-playlists (Alka Yagnik Radio, Jeet-Pritam Radio, Daily Smart Mix, etc.) were created
        expect(manager.playlists, isEmpty);
        expect(manager.artistMixes, isEmpty);
        expect(manager.genreMixes, isEmpty);
        expect(manager.smartMixes, isEmpty);

        // Verify that manual creation still works properly
        final customPl = await manager.createPlaylist('My Workout Mix');
        expect(manager.playlists.length, equals(1));
        expect(manager.playlists.first.title, equals('My Workout Mix'));
        expect(customPl.id, isNotEmpty);
      },
    );
  });
}
