import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
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

    test(
      'cycleRepeatAndAutoplayMode cycles through playback modes properly',
      () async {
        // 1. From default (Autoplay=true, LoopMode=off) -> LoopMode.all (Autoplay=false)
        await manager.cycleRepeatAndAutoplayMode();
        expect(manager.loopMode, LoopMode.all);
        expect(manager.autoplay, isFalse);

        // 2. From LoopMode.all -> LoopMode.one (Repeat current)
        await manager.cycleRepeatAndAutoplayMode();
        expect(manager.loopMode, LoopMode.one);

        // 3. From LoopMode.one -> LoopMode.off (Repeat off, autoplay=false)
        await manager.cycleRepeatAndAutoplayMode();
        expect(manager.loopMode, LoopMode.off);
        expect(manager.autoplay, isFalse);

        // 4. From LoopMode.off -> LoopMode.off with Autoplay=true (Infinite Radio)
        await manager.cycleRepeatAndAutoplayMode();
        expect(manager.loopMode, LoopMode.off);
        expect(manager.autoplay, isTrue);
      },
    );
  });
}
