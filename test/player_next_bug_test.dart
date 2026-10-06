import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (MethodCall methodCall) async {
            return {'id': 'fake_player_id'};
          },
        );
  });

  group('Player Next Bug Tests', () {
    late MusicPlayerManager manager;
    late DatabaseService db;

    const singleSong = Song(
      id: 'solo_song_999',
      title: 'Solo Single Song',
      artist: 'Independent',
      album: 'Single Album',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/stream.mp3',
      duration: Duration(seconds: 210),
    );

    const fallbackSong = Song(
      id: 'fallback_song_888',
      title: 'Fallback Distinct Song',
      artist: 'Other Artist',
      album: 'Other Album',
      coverUrl: 'https://example.com/cover2.jpg',
      audioUrl: 'https://example.com/stream2.mp3',
      duration: Duration(seconds: 180),
    );

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();

      manager = MusicPlayerManager();
    });

    test(
      'next() with 1 song queue and no distinct tracks stops playback and never replays the same song',
      () async {
        await manager.playPlaylist([singleSong]);
        manager.allSongs.clear();
        manager.allSongs.add(singleSong);
        expect(manager.currentSong?.id, equals(singleSong.id));
        expect(manager.queue.length, equals(1));
        expect(manager.loopMode, equals(LoopMode.off));

        await manager.next();

        // Must stop gracefully without replaying singleSong
        expect(manager.isPlaying, isFalse);
      },
    );

    test(
      'next() with recommendations unavailable falls back to distinct track from library/history',
      () async {
        await manager.playPlaylist([singleSong]);
        manager.allSongs.clear();
        manager.allSongs.addAll([singleSong, fallbackSong]);
        expect(manager.currentSong?.id, equals(singleSong.id));
        expect(manager.queue.length, equals(1));

        await manager.next();

        // Must play the distinct fallback song
        expect(manager.currentSong?.id, equals(fallbackSong.id));
      },
    );
  });
}
