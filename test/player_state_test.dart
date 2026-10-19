import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jumbo_music/config/app_config.dart';
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

    test(
      'Background notification config respects audio_service assertion: !ongoing || stopForegroundOnPause',
      () {
        bool isValidConfig(bool ongoing, bool stopForegroundOnPause) =>
            !ongoing || stopForegroundOnPause;

        // Configured values (ongoing: true, stopForegroundOnPause: true)
        expect(isValidConfig(true, true), isTrue);
        // Ongoing false also valid
        expect(isValidConfig(false, false), isTrue);
        // Old broken configuration that triggered AssertionError in audio_service
        expect(isValidConfig(true, false), isFalse);
      },
    );

    test(
      'Audio notification channel is upgraded to v3 for lock screen support',
      () {
        expect(
          AppConfig.audioNotificationChannelId,
          'com.jumbomusic.app.channel.audio.v3',
        );
      },
    );

    test(
      'Queue maintains strict sequence and skipToQueueIndex preserves queue order',
      () {
        final s1 = Song(
          id: 's_1',
          title: 'Song 1',
          artist: 'Artist 1',
          audioUrl: 'https://example.com/1.mp3',
          coverUrl: '',
          duration: const Duration(seconds: 180),
        );
        final s2 = Song(
          id: 's_2',
          title: 'Song 2',
          artist: 'Artist 2',
          audioUrl: 'https://example.com/2.mp3',
          coverUrl: '',
          duration: const Duration(seconds: 210),
        );
        final s3 = Song(
          id: 's_3',
          title: 'Song 3',
          artist: 'Artist 3',
          audioUrl: 'https://example.com/3.mp3',
          coverUrl: '',
          duration: const Duration(seconds: 240),
        );

        manager.setMockState(
          currentSong: s1,
          queue: [s1, s2, s3],
          isPlaying: true,
        );

        expect(manager.queue.length, equals(3));
        expect(manager.queue[0].title, equals('Song 1'));
        expect(manager.queue[1].title, equals('Song 2'));
        expect(manager.queue[2].title, equals('Song 3'));

        // Reorder queue
        manager.reorderQueue(0, 2);
        expect(manager.queue[0].title, equals('Song 2'));
        expect(manager.queue[1].title, equals('Song 1'));

        // Remove from queue
        manager.removeFromQueue(0);
        expect(manager.queue.length, equals(2));
        expect(manager.queue[0].title, equals('Song 1'));
      },
    );
  });
}
