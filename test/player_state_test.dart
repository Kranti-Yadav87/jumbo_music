import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_player_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusicPlayerManager Playback State Synchronization Tests', () {
    late MusicPlayerManager manager;

    setUp(() {
      manager = MusicPlayerManager();
    });

    test(
      'Initial playback state is not playing and not buffering without active song',
      () {
        expect(manager.isPlaying, isFalse);
        expect(manager.isBuffering, isFalse);
      },
    );

    test('Queue and favorite toggle logic works consistently', () {
      final song1 = Song(
        id: 'test_1',
        title: 'Song 1',
        artist: 'Artist 1',
        album: 'Album 1',
        coverUrl: 'https://example.com/cover1.jpg',
        audioUrl: 'https://example.com/audio1.mp3',
        duration: const Duration(seconds: 200),
      );

      manager.toggleFavorite(song1.id);
      expect(manager.isFavorite(song1.id), isTrue);

      manager.toggleFavorite(song1.id);
      expect(manager.isFavorite(song1.id), isFalse);
    });

    test('Shuffle mode toggles cleanly', () async {
      final initialShuffle = manager.isShuffle;
      await manager.toggleShuffle();
      expect(manager.isShuffle, !initialShuffle);
      await manager.toggleShuffle();
      expect(manager.isShuffle, initialShuffle);
    });
  });
}
