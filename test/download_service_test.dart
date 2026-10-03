import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/download_service.dart';
import 'package:jumbo_music/services/storage/downloaded_file.dart';

class FakeFileDownloader implements FileDownloaderDelegate {
  final Set<String> existingPaths = {};
  final List<String> deletedPaths = [];
  final Map<String, int> downloadedUrls = {};

  @override
  bool get isSupported => true;

  @override
  Future<DownloadedFile> download(String url, String id) async {
    final path = '/mock/storage/offline_$id.mp3';
    existingPaths.add(path);
    downloadedUrls[url] = 1024 * 1024 * 5; // 5 MB
    return DownloadedFile(path: path, bytes: 1024 * 1024 * 5);
  }

  @override
  Future<bool> exists(String path) async {
    return existingPaths.contains(path);
  }

  @override
  Future<Uri?> playableUri(String path) async {
    if (existingPaths.contains(path)) {
      return Uri.file(path);
    }
    return null;
  }

  @override
  Future<void> delete(String path) async {
    existingPaths.remove(path);
    deletedPaths.add(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadService Unit Tests with Fake Downloader', () {
    late DatabaseService db;
    late DownloadService downloadService;
    late FakeFileDownloader fakeDownloader;

    const testSong = Song(
      id: 'song_test_dl_1',
      title: 'Offline Test Track',
      artist: 'Studio Artist',
      duration: Duration(seconds: 210),
      audioUrl: 'https://example.com/audio/test1.mp3',
      coverUrl: 'https://example.com/art.jpg',
    );

    setUp(() async {
      fakeDownloader = FakeFileDownloader();
      DownloadService.delegate = fakeDownloader;

      db = DatabaseService.instance;
      await db.init();
      await db.deleteScopedLocalData('user_test_scope_1');
      await db.switchUserScope(null);
      await db.clearAllUserData();

      downloadService = DownloadService();
      downloadService.hydrateFromDatabase();
    });

    tearDown(() {
      DownloadService.delegate = const DefaultFileDownloaderDelegate();
    });

    test('save a download -> restart DownloadService -> item still listed', () async {
      expect(downloadService.downloadedSongs, isEmpty);
      expect(downloadService.isDownloaded(testSong.id), isFalse);

      // Download the song via fake downloader
      await downloadService.downloadSong(testSong);

      expect(downloadService.isDownloaded(testSong.id), isTrue);
      expect(downloadService.downloadedSongs.length, equals(1));
      expect(downloadService.downloadedSongs.first.title, equals('Offline Test Track'));

      // Simulate app restart / new hydration
      downloadService.hydrateFromDatabase();

      expect(downloadService.isDownloaded(testSong.id), isTrue);
      expect(downloadService.downloadedItems.first.localPath, contains('offline_song_test_dl_1.mp3'));
      expect(downloadService.downloadedItems.first.fileSize, contains('MB'));
    });

    test('switch scope -> list changes according to active user scope', () async {
      // 1. In Guest Scope: save download
      await downloadService.downloadSong(testSong);
      expect(downloadService.downloadedSongs.length, equals(1));

      // 2. Switch to authenticated user scope
      await db.switchUserScope('user_test_scope_1');
      // DownloadService listener rehydrates automatically on scope switch
      expect(downloadService.downloadedSongs, isEmpty);
      expect(downloadService.isDownloaded(testSong.id), isFalse);

      // 3. Switch back to guest
      await db.switchUserScope(null);
      expect(downloadService.downloadedSongs.length, equals(1));
      expect(downloadService.isDownloaded(testSong.id), isTrue);
    });

    test('remove download -> local file delete called on delegate', () async {
      await downloadService.downloadSong(testSong);
      expect(downloadService.downloadedSongs.length, equals(1));
      final savedPath = downloadService.downloadedItems.first.localPath;

      // Remove download
      downloadService.removeDownload(testSong.id);

      // Allow unawaited async deletion to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(downloadService.downloadedSongs, isEmpty);
      expect(downloadService.isDownloaded(testSong.id), isFalse);
      expect(fakeDownloader.deletedPaths, contains(savedPath));
      expect(await fakeDownloader.exists(savedPath), isFalse);
    });

    test('playableUriFor returns local file Uri when present', () async {
      await downloadService.downloadSong(testSong);
      final uri = await downloadService.playableUriFor(testSong.id);

      expect(uri, isNotNull);
      expect(uri!.isScheme('file'), isTrue);
      expect(uri.path, contains('offline_song_test_dl_1.mp3'));
    });
  });
}
