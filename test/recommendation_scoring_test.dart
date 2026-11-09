import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/api/music_tag_classifier.dart';
import 'package:jumbo_music/services/api/song_parser_utils.dart';
import 'package:jumbo_music/services/api/youtube_search_service.dart';
import 'package:jumbo_music/services/recommendation/ai_recommendation_engine.dart';

void main() {
  group('YouTube + Spotify Dual-Engine Recommendation Tests', () {
    final engine = AiRecommendationEngine.instance;

    final seed = Song(
      id: 'yt_mOB1S1qXcPQ',
      title: 'Heer',
      artist: 'Afusic & AliSoomroMusic',
      album: 'Heer',
      duration: const Duration(minutes: 3, seconds: 17),
      audioUrl: 'https://music.youtube.com/watch?v=mOB1S1qXcPQ',
      coverUrl: 'https://example.com/heer.jpg',
      genre: 'YouTube Music',
      language: 'Hindi',
      releaseYear: '2024',
      quality: 'YouTube HD',
      lyrics: '',
      isLiveStream: false,
    );

    final candidateA = Song(
      id: 'yt_0_9TCak--cw',
      title: 'Pal Pal',
      artist: 'Afusic & AliSoomroMusic',
      album: 'Pal Pal',
      duration: const Duration(minutes: 2, seconds: 27),
      audioUrl: 'https://music.youtube.com/watch?v=0_9TCak--cw',
      coverUrl: 'https://example.com/palpal.jpg',
      genre: 'YouTube Music',
      language: 'Hindi',
      releaseYear: '2025',
      quality: 'YouTube HD',
      lyrics: '',
      isLiveStream: false,
    );

    final candidateB = Song(
      id: 'js_bairan_123',
      title: 'Bairan',
      artist: 'Banjaare',
      album: 'Bairan',
      duration: const Duration(minutes: 3, seconds: 40),
      audioUrl: 'https://example.com/bairan.mp3',
      coverUrl: 'https://example.com/bairan.jpg',
      genre: 'Indie',
      language: 'Hindi',
      releaseYear: '2026',
      quality: '320kbps',
      lyrics: '',
      isLiveStream: false,
    );

    setUp(() {
      engine.resetForTesting();
    });

    test('The 30-Second Rule: Skip penalty decreases score', () {
      final baseScore = engine.scoreCandidate(seed, candidateA);

      // Record a skip (< 30s)
      engine.recordSkip(candidateA.id);
      final scoreAfter1Skip = engine.scoreCandidate(seed, candidateA);
      expect(scoreAfter1Skip, lessThan(baseScore));

      // Record 3 skips -> should be completely suppressed (-100.0)
      engine.recordSkip(candidateA.id);
      engine.recordSkip(candidateA.id);
      final scoreAfter3Skips = engine.scoreCandidate(seed, candidateA);
      expect(scoreAfter3Skips, equals(-100.0));
    });

    test('The 30-Second Rule: Completed listen increases score', () {
      final baseScore = engine.scoreCandidate(seed, candidateA);

      // Record completed listen (>= 30s)
      engine.recordCompletedListen(candidateA.id);
      final scoreAfterListen = engine.scoreCandidate(seed, candidateA);
      expect(scoreAfterListen, greaterThan(baseScore));
    });

    test('Adding to personal playlist provides strong affinity signal (+40 pts)', () {
      final baseScore = engine.scoreCandidate(seed, candidateB);

      engine.recordPlaylistAdd(candidateB.id);
      final scoreAfterPlaylistAdd = engine.scoreCandidate(seed, candidateB);
      expect(scoreAfterPlaylistAdd, greaterThan(baseScore));
      expect(scoreAfterPlaylistAdd - baseScore, closeTo(0.40, 0.05));
    });

    test('Listening on Loop provides heavy multiplier signal (+50 pts)', () {
      final baseScore = engine.scoreCandidate(seed, candidateA);

      engine.recordLoop(candidateA.id);
      final scoreAfterLoop = engine.scoreCandidate(seed, candidateA);
      expect(scoreAfterLoop, greaterThan(baseScore));
      expect(scoreAfterLoop - baseScore, closeTo(0.25, 0.05));

      engine.recordLoop(candidateA.id);
      final scoreAfter2Loops = engine.scoreCandidate(seed, candidateA);
      expect(scoreAfter2Loops - baseScore, closeTo(0.50, 0.05));
    });

    test('YouTube Radio Continuation bonus boosts session continuity', () {
      final baseScore = engine.scoreCandidate(seed, candidateA);

      // Mark candidateA as recommended by YouTube Music Radio
      engine.setYouTubeRadioRecommendations([candidateA.id]);
      final scoreWithRadio = engine.scoreCandidate(seed, candidateA);
      expect(scoreWithRadio, greaterThan(baseScore));
      expect(scoreWithRadio - baseScore, closeTo(0.60, 0.05));
    });

    test('Dual-Engine: YouTube and Spotify/JioSaavn candidates co-exist without error', () {
      // Mark candidateA as YouTube radio continuation
      engine.setYouTubeRadioRecommendations([candidateA.id]);
      // Mark candidateB with Spotify collaborative transition from seed
      engine.recordTransition(seed.id, candidateB.id);

      final scoreYt = engine.scoreCandidate(seed, candidateA);
      final scoreSpotify = engine.scoreCandidate(seed, candidateB);

      // Both must compute clean numeric scores without throwing or NaN
      expect(scoreYt.isFinite, isTrue);
      expect(scoreSpotify.isFinite, isTrue);
      expect(scoreYt, greaterThan(0.0));
      expect(scoreSpotify, greaterThan(0.0));
    });

    test('YouTubeSearchService parseRadioResults parses InnerTube response structure', () {
      final fixture = {
        'contents': {
          'singleColumnMusicWatchNextResultsRenderer': {
            'tabbedRenderer': {
              'watchNextTabbedResultsRenderer': {
                'tabs': [
                  {
                    'tabRenderer': {
                      'content': {
                        'musicQueueRenderer': {
                          'content': {
                            'playlistPanelRenderer': {
                              'contents': [
                                {
                                  'playlistPanelVideoRenderer': {
                                    'videoId': 'test_vid_123',
                                    'title': {
                                      'runs': [{'text': 'Pal Pal'}]
                                    },
                                    'shortBylineText': {
                                      'runs': [{'text': 'Afusic'}]
                                    },
                                    'longBylineText': {
                                      'runs': [{'text': 'Afusic • Pal Pal • 2025'}]
                                    },
                                    'lengthText': {
                                      'runs': [{'text': '2:45'}]
                                    },
                                    'thumbnail': {
                                      'thumbnails': [
                                        {'url': 'https://example.com/thumb.jpg'}
                                      ]
                                    }
                                  }
                                }
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      };

      final parsed = YouTubeSearchService.parseRadioResults(fixture);
      expect(parsed.length, equals(1));
      expect(parsed.first.id, equals('yt_test_vid_123'));
      expect(parsed.first.title, equals('Pal Pal'));
      expect(parsed.first.artist, equals('Afusic'));
      expect(parsed.first.duration.inSeconds, equals(165));
      expect(parsed.first.releaseYear, equals('2025'));
    });

    test('SongParserUtils.songDeduplicationKey preserves distinct artists with same title', () {
      final song1 = Song(
        id: 's1',
        title: 'Heer',
        artist: 'Afusic & AliSoomroMusic',
        album: 'Heer',
        duration: const Duration(seconds: 197),
        audioUrl: 'https://example.com/heer1.mp3',
        coverUrl: '',
      );

      final song2 = Song(
        id: 's2',
        title: 'Heer',
        artist: 'Harshdeep Kaur',
        album: 'Jab Tak Hai Jaan',
        duration: const Duration(seconds: 240),
        audioUrl: 'https://example.com/heer2.mp3',
        coverUrl: '',
      );

      final key1 = SongParserUtils.searchDeduplicationKey(song1);
      final key2 = SongParserUtils.searchDeduplicationKey(song2);

      expect(key1, isNot(equals(key2)));
      expect(key1, contains('heer'));
      expect(key1, contains('afusic'));
      expect(key2, contains('heer'));
      expect(key2, contains('harshdeep'));
    });

    test('MusicTagClassifier recognizes Romanized Desi Indie tracks as Indic/Hindi', () {
      final langHeer = MusicTagClassifier.detectTextLanguage(
        title: 'Heer',
        artist: 'Afusic & AliSoomroMusic',
      );
      expect(langHeer, equals('Hindi'));

      final langPalPal = MusicTagClassifier.detectTextLanguage(
        title: 'Pal Pal',
        artist: 'Afusic',
      );
      expect(langPalPal, equals('Hindi'));

      final langAarzu = MusicTagClassifier.detectTextLanguage(
        title: 'Aarzu',
        artist: 'Noor, Khan & Madhurxo',
      );
      expect(langAarzu, equals('Hindi'));
    });

    test('MusicTagClassifier.isEraCompatible links adjacent modern and retro eras', () {
      expect(
        MusicTagClassifier.isEraCompatible(
          MusicEra.genZModern,
          MusicEra.era2010s,
        ),
        isTrue,
      );
      expect(
        MusicTagClassifier.isEraCompatible(
          MusicEra.era2010s,
          MusicEra.era2000s,
        ),
        isTrue,
      );
      expect(
        MusicTagClassifier.isEraCompatible(
          MusicEra.vintage70s,
          MusicEra.genZModern,
        ),
        isFalse,
      );
    });

    test('YouTube Radio recommendations across adjacent compatible eras are scored and retained', () {
      final seed2010s = Song(
        id: 'yt_seed_2010s',
        title: 'Tum Hi Ho',
        artist: 'Arijit Singh',
        album: 'Aashiqui 2',
        duration: const Duration(seconds: 260),
        audioUrl: 'https://example.com/tumhiho.mp3',
        coverUrl: '',
        genre: 'Bollywood',
        language: 'Hindi',
        releaseYear: '2013',
      );

      final candGenZ = Song(
        id: 'yt_cand_genz',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        album: 'Brahmastra',
        duration: const Duration(seconds: 268),
        audioUrl: 'https://example.com/kesariya.mp3',
        coverUrl: '',
        genre: 'Bollywood',
        language: 'Hindi',
        releaseYear: '2022',
      );

      engine.setYouTubeRadioRecommendations([candGenZ.id]);
      final score = engine.scoreCandidate(seed2010s, candGenZ);

      // Must NOT be disqualified with -100.0
      expect(score, greaterThan(0.0));
    });
  });
}
