import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/widgets/home/continue_playing_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Verification Tests', () {
    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();
    });

    test('DatabaseService logout must end with isLoggedIn == false', () async {
      // 1. Log in
      await db.login(
        email: 'testuser@jumbomusic.app',
        name: 'Test User',
        userId: 'JM-99999',
        uid: 'test_uid_123',
      );
      expect(db.isLoggedIn, isTrue);
      expect(db.userName, equals('Test User'));

      // 2. Perform Logout
      await db.logout();

      // 3. Verify state
      expect(db.isLoggedIn, isFalse);
      expect(db.currentScope, equals('guest'));
      expect(db.userId, isEmpty);
      expect(db.userName, equals('Guest Explorer'));
    });

    test('ContinuePlayingSection.recentSongs handles current song, history, deduplication and limits', () {
      const current = Song(
        id: 'current_1',
        title: 'Current Song',
        artist: 'Current Artist',
        duration: Duration(seconds: 180),
        audioUrl: 'https://example.com/curr.mp3',
        coverUrl: '',
      );

      final history = [
        {
          'song': {
            'id': 'current_1', // duplicate of current
            'title': 'Current Song',
            'artist': 'Current Artist',
            'duration': 180,
            'audioUrl': 'https://example.com/curr.mp3',
          },
        },
        {
          'song': {
            'id': 'hist_1',
            'title': 'History Song 1',
            'artist': 'Artist 1',
            'duration': 200,
            'audioUrl': 'https://example.com/h1.mp3',
          },
        },
        {
          'song': {
            'id': 'hist_no_url',
            'title': 'No Audio Song',
            'artist': 'Artist 2',
            'duration': 150,
            'audioUrl': '', // should be filtered out
          },
        },
        {
          'song': 'invalid_map', // malformed entry
        },
        {
          'song': {
            'id': 'hist_2',
            'title': 'History Song 2',
            'artist': 'Artist 2',
            'duration': 210,
            'audioUrl': 'https://example.com/h2.mp3',
          },
        },
      ];

      final result = ContinuePlayingSection.recentSongs(history, current, max: 2);
      // Expected: max 2 items, current first, hist_1 second, no duplicate current_1
      expect(result.length, equals(2));
      expect(result[0].id, equals('current_1'));
      expect(result[1].id, equals('hist_1'));

      final allResult = ContinuePlayingSection.recentSongs(history, null);
      // Without current song: current_1, hist_1, and hist_2 (skips invalid and no-audio)
      expect(allResult.length, equals(3));
      expect(allResult[0].id, equals('current_1'));
      expect(allResult[1].id, equals('hist_1'));
      expect(allResult[2].id, equals('hist_2'));
    });

    test('togglePlay completes promptly without blocking', () async {
      final manager = MusicPlayerManager();
      final stopwatch = Stopwatch()..start();

      // togglePlay when queue is empty or without active song should complete immediately
      await manager.togglePlay();
      stopwatch.stop();

      // Ensure execution took less than 1 second (no hanging/awaiting stream finishes)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
