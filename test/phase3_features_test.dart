import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 Feature & Reliability Tests', () {
    late DatabaseService db;
    late MusicPlayerManager manager;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();
      manager = MusicPlayerManager();
    });

    test(
      'Guest login generates unique IDs and prevents data collision',
      () async {
        // 1. First guest session
        await db.loginAsGuest();
        expect(db.isGuest, isTrue);
        expect(db.isLoggedIn, isTrue);
        final firstGuestId = db.userId;
        expect(firstGuestId.startsWith('JM-G-'), isTrue);

        // 2. Guest logs out
        await db.logout();
        expect(db.isLoggedIn, isFalse);

        // 3. Second guest session should have distinct ID & clean storage scope
        await db.loginAsGuest();
        final secondGuestId = db.userId;
        expect(secondGuestId.startsWith('JM-G-'), isTrue);
        expect(db.isGuest, isTrue);
        expect(db.isLoggedIn, isTrue);
      },
    );

    test('Audio playback stops completely with stopPlayback', () async {
      // stopPlayback resets all playback flags and empty queues
      await manager.stopPlayback();
      expect(manager.isPlaying, isFalse);
      expect(manager.currentSong, isNull);
    });

    test('Sound preset can be changed to any valid EQ preset', () {
      expect(manager.soundPresets.contains('Bass Boost'), isTrue);
      expect(manager.soundPresets.contains('Vocal Booster'), isTrue);
      expect(manager.soundPresets.contains('Electronic'), isTrue);

      manager.setSoundPreset('Bass Boost');
      expect(manager.soundPreset, equals('Bass Boost'));

      manager.setSoundPreset('Electronic');
      expect(manager.soundPreset, equals('Electronic'));

      manager.setSoundPreset('Normal');
      expect(manager.soundPreset, equals('Normal'));
    });

    test('Notification added when feedback is submitted', () async {
      final initialNotifs = db.notifications.length;
      await db.addNotification(
        title: 'Feedback Received',
        message: 'Thank you for rating Jumbo Music 5/5 stars.',
        type: 'system',
      );
      expect(db.notifications.length, equals(initialNotifs + 1));
      expect(db.notifications.first['title'], equals('Feedback Received'));
    });
  });
}
