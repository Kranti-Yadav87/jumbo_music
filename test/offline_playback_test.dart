import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/download_service.dart';
import 'package:jumbo_music/services/storage/downloaded_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Playback & Download Tests', () {
    test('DownloadedFile holds valid path and bytes', () {
      const file = DownloadedFile(path: '/data/user/0/audio/123.mp3', bytes: 4194304);
      expect(file.path, '/data/user/0/audio/123.mp3');
      expect(file.bytes, 4194304);
    });

    test('DownloadItem encapsulates offline file path and metadata', () {
      final song = Song(
        id: 'test_song_1',
        title: 'Offline Master',
        artist: 'Jumbo Studio',
        audioUrl: 'https://example.com/stream.mp3',
        coverUrl: 'https://example.com/cover.jpg',
        duration: const Duration(seconds: 180),
      );

      final item = DownloadItem(
        song: song,
        fileSize: '4.2 MB',
        downloadedAt: DateTime.now(),
        localPath: '/local/storage/test_song_1.mp3',
      );

      expect(item.song.title, 'Offline Master');
      expect(item.fileSize, '4.2 MB');
      expect(item.localPath, '/local/storage/test_song_1.mp3');
    });
  });
}
