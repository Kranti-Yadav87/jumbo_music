import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/models/playlist.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/recommendation/ai_recommendation_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiRecommendationEngine Unit Tests', () {
    late AiRecommendationEngine engine;

    final songA = Song(
      id: 'song_a',
      title: 'Kesariya Love',
      artist: 'Arijit Singh, Pritam',
      album: 'Brahmastra',
      audioUrl: 'https://example.com/a.mp3',
      coverUrl: 'https://example.com/a.jpg',
      duration: const Duration(seconds: 240),
    );

    final songB = Song(
      id: 'song_b',
      title: 'Apna Bana Le',
      artist: 'Arijit Singh, Sachin-Jigar',
      album: 'Bhediya',
      audioUrl: 'https://example.com/b.mp3',
      coverUrl: 'https://example.com/b.jpg',
      duration: const Duration(seconds: 210),
    );

    final songParty = Song(
      id: 'song_party',
      title: 'Kala Chashma Party Dance Remix',
      artist: 'Badshah, Neha Kakkar',
      album: 'Baar Baar Dekho',
      audioUrl: 'https://example.com/party.mp3',
      coverUrl: 'https://example.com/party.jpg',
      duration: const Duration(seconds: 190),
    );

    final songSukoon = Song(
      id: 'song_sukoon',
      title: 'Kasoor Lofi Sukoon Acoustic',
      artist: 'Prateek Kuhad',
      album: 'Kasoor',
      audioUrl: 'https://example.com/sukoon.mp3',
      coverUrl: 'https://example.com/sukoon.jpg',
      duration: const Duration(seconds: 200),
    );

    setUp(() async {
      engine = AiRecommendationEngine.instance;
      engine.resetForTesting();
      await DatabaseService.instance.switchUserScope('test_engine_user');
      await DatabaseService.instance.clearHistory();
    });

    test(
      'Pillar 1 - Collaborative Filtering: recordTransition increases score',
      () {
        final initialScore = engine.calculateCollaborativeScore(songA, songB);

        engine.recordTransition(songA.id, songB.id);
        engine.recordTransition(songA.id, songB.id);

        final boostedScore = engine.calculateCollaborativeScore(songA, songB);
        expect(boostedScore, greaterThan(initialScore));
      },
    );

    test(
      'Pillar 1 - Collaborative Filtering: playlist co-occurrence increases score',
      () async {
        final playlist = Playlist(
          id: 'pl_collab',
          title: 'Romantic Duo',
          description: 'Test playlist',
          coverUrl: '',
          songIds: [songA.id, songB.id],
          songs: [songA, songB],
          type: PlaylistType.custom,
        );
        await DatabaseService.instance.addCustomPlaylist(playlist);

        final score = engine.calculateCollaborativeScore(songA, songB);
        expect(score, greaterThanOrEqualTo(0.40));
      },
    );

    test('Pillar 2 - Content-Based Filtering: Tempo and Mood detection', () {
      expect(engine.estimateTempo(songParty), SongTempoCategory.upbeat);
      expect(engine.estimateTempo(songSukoon), SongTempoCategory.slow);
      expect(engine.estimateTempo(songA), SongTempoCategory.midTempo);

      expect(engine.classifyMood(songParty), SongMoodCategory.energetic);
      expect(engine.classifyMood(songSukoon), SongMoodCategory.calmSukoon);
      expect(engine.classifyMood(songA), SongMoodCategory.romantic);
    });

    test(
      'Pillar 2 - Content-Based Filtering: Similar artists and genre score higher',
      () {
        final scoreSimilar = engine.calculateContentScore(songA, songB);
        final scoreDissimilar = engine.calculateContentScore(songA, songParty);

        expect(scoreSimilar, greaterThan(scoreDissimilar));
      },
    );

    test(
      'Pillar 3 - Behavioral Signals: Skip penalty reduces candidate score',
      () {
        final initialScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );

        engine.recordSkip(songB.id);
        final oneSkipScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        expect(oneSkipScore, lessThan(initialScore));

        engine.recordSkip(songB.id);
        final twoSkipsScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        expect(twoSkipsScore, lessThan(oneSkipScore));

        engine.recordSkip(songB.id); // 3 skips -> suppress
        final threeSkipsScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        expect(threeSkipsScore, equals(-1.0));
        expect(engine.scoreCandidate(songA, songB), equals(-100.0));
      },
    );

    test(
      'Pillar 3 - Behavioral Signals: Search history match boosts candidate',
      () async {
        await DatabaseService.instance.addSearchQuery('Bhediya');

        final score = engine.calculateContextualAndBehavioralScore(songB);
        expect(score, greaterThan(0.0));
      },
    );

    test(
      'Pillar 3 - Contextual Modulation: Late-night favors calm/sukoon/slow songs',
      () {
        engine.nowProvider = () => DateTime(2026, 10, 13, 23, 30);

        final sukoonScore = engine.calculateContextualAndBehavioralScore(
          songSukoon,
        );
        final partyScore = engine.calculateContextualAndBehavioralScore(
          songParty,
        );

        expect(sukoonScore, greaterThan(partyScore));
      },
    );

    test('selectBestNextSong chooses highest scoring compatible track', () {
      final best = engine.selectBestNextSong(
        currentSong: songA,
        candidates: [songParty, songB, songSukoon],
      );

      expect(best, isNotNull);
      expect(best!.id, equals(songB.id));
    });

    test(
      'buildSmartQueue builds tailored queue starting with seed track',
      () async {
        final queue = await engine.buildSmartQueue(
          seedSong: songA,
          existingQueue: [songB, songParty],
          targetSize: 10,
        );

        expect(queue.isNotEmpty, isTrue);
        expect(queue.first.id, equals(songA.id));
        expect(queue.any((s) => s.id == songB.id), isTrue);
      },
    );
  });
}
