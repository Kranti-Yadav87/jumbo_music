import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Mode & Offline Downloads Integration Tests', () {
    late DatabaseService db;
    late DownloadService downloadService;

    const testSong = Song(
      id: 'song_guest_dl_test',
      title: 'Guest Offline Song',
      artist: 'Independent Artist',
      duration: Duration(seconds: 180),
      audioUrl: 'https://example.com/stream.mp3',
      coverUrl: '',
    );

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();

      downloadService = DownloadService();
      downloadService.hydrateFromDatabase();
    });

    test('isGuest and loginAsGuest properly set guest state and isolate scopes', () async {
      // 1. Explicitly login as guest
      await db.loginAsGuest();
      expect(db.isGuest, isTrue);
      expect(db.isLoggedIn, isTrue);
      expect(db.userName, equals('Guest Listener'));
      expect(db.userId.startsWith('JM-G-'), isTrue);

      // 2. Simulate authenticated user login
      await db.login(
        email: 'listener@jumbo.app',
        name: 'Jumbo Fan',
        uid: 'user_fan_101',
      );
      expect(db.isGuest, isFalse);
      expect(db.isLoggedIn, isTrue);
      expect(db.userName, equals('Jumbo Fan'));
      expect(db.userId, isNotEmpty);

      // 3. Logout sets isLoggedIn to false and isGuest to false
      await db.logout();
      expect(db.isLoggedIn, isFalse);
      expect(db.isGuest, isFalse);

      // 4. Re-enter guest mode via loginAsGuest
      await db.loginAsGuest();
      expect(db.isGuest, isTrue);
      expect(db.isLoggedIn, isTrue);
      expect(db.userName, equals('Guest Listener'));
      expect(db.userId.startsWith('JM-G-'), isTrue);
    });

    test('User downloads remain preserved and isolated between user scopes', () async {
      // 1. Sign in as user A and save download
      await db.login(
        email: 'userA@jumbo.app',
        name: 'User A',
        uid: 'user_A',
      );
      await db.saveDownload(
        song: testSong,
        fileSize: '3.4 MB',
        localPath: '/mock/storage/offline_userA.mp3',
      );
      expect(db.isDownloaded(testSong.id), isTrue);
      expect(downloadService.isDownloaded(testSong.id), isTrue);

      // 2. Sign in as user B - downloads should not leak
      await db.login(
        email: 'userB@jumbo.app',
        name: 'User B',
        uid: 'user_B',
      );
      expect(db.isDownloaded(testSong.id), isFalse);
      expect(downloadService.isDownloaded(testSong.id), isFalse);

      // 3. Switch back to user A - download is preserved
      await db.login(
        email: 'userA@jumbo.app',
        name: 'User A',
        uid: 'user_A',
      );
      expect(db.isDownloaded(testSong.id), isTrue);
      expect(downloadService.isDownloaded(testSong.id), isTrue);
    });
  });
}
