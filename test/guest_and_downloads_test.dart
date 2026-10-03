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

    test('isGuest and loginAsGuest properly reset user profile and scope', () async {
      // 1. Initial guest state
      expect(db.isGuest, isTrue);
      expect(db.isLoggedIn, isFalse);
      expect(db.userName, equals('Guest Explorer'));
      expect(db.userId, isEmpty);

      // 2. Simulate login
      await db.login(
        email: 'listener@jumbo.app',
        name: 'Jumbo Fan',
        uid: 'user_fan_101',
      );
      expect(db.isGuest, isFalse);
      expect(db.isLoggedIn, isTrue);
      expect(db.userName, equals('Jumbo Fan'));
      expect(db.userId, isNotEmpty);

      // 3. Switch back via loginAsGuest
      await db.loginAsGuest();
      expect(db.isGuest, isTrue);
      expect(db.isLoggedIn, isFalse);
      expect(db.userName, equals('Guest Explorer'));
      expect(db.userId, isEmpty);
    });

    test('Guest downloads remain preserved and isolated from signed-in user', () async {
      // 1. Save download in guest mode
      await db.saveDownload(
        song: testSong,
        fileSize: '3.4 MB',
        localPath: '/mock/storage/offline_guest.mp3',
      );
      expect(db.isDownloaded(testSong.id), isTrue);
      expect(downloadService.isDownloaded(testSong.id), isTrue);

      // 2. Sign in as authenticated user
      await db.login(
        email: 'listener@jumbo.app',
        name: 'Jumbo Fan',
        uid: 'user_fan_101',
      );
      expect(db.isDownloaded(testSong.id), isFalse);
      expect(downloadService.isDownloaded(testSong.id), isFalse);

      // 3. Return to guest mode
      await db.loginAsGuest();
      expect(db.isDownloaded(testSong.id), isTrue);
      expect(downloadService.isDownloaded(testSong.id), isTrue);
    });
  });
}
