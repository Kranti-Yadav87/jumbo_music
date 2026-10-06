import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_player_manager.dart';

class FakeAudioPlayerEngine implements AudioPlayerEngine {
  final StreamController<PlayerState> playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<Duration> bufferedPositionController =
      StreamController<Duration>.broadcast();

  bool isPlayingState = false;
  AudioSource? lastSetSource;
  int stopCallCount = 0;
  int playCallCount = 0;
  int setSourceCallCount = 0;

  Completer<void>? setAudioSourceHangCompleter;
  Duration setAudioSourceDelay = Duration.zero;
  bool shouldThrowOnSetAudioSource = false;

  @override
  Stream<PlayerState> get playerStateStream => playerStateController.stream;
  @override
  Stream<Duration> get positionStream => positionController.stream;
  @override
  Stream<Duration?> get durationStream => durationController.stream;
  @override
  Stream<Duration> get bufferedPositionStream =>
      bufferedPositionController.stream;
  @override
  bool get playing => isPlayingState;

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
  }) async {
    setSourceCallCount++;
    lastSetSource = source;
    if (setAudioSourceHangCompleter != null) {
      await setAudioSourceHangCompleter!.future;
    }
    if (setAudioSourceDelay > Duration.zero) {
      await Future.delayed(setAudioSourceDelay);
    }
    if (shouldThrowOnSetAudioSource) {
      throw Exception('Fake source load failed');
    }
    return const Duration(seconds: 200);
  }

  @override
  Future<void> play() async {
    playCallCount++;
    isPlayingState = true;
    playerStateController.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    isPlayingState = false;
    playerStateController.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    isPlayingState = false;
    playerStateController.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setLoopMode(LoopMode loopMode) async {}
  @override
  Future<void> dispose() async {
    await playerStateController.close();
    await positionController.close();
    await durationController.close();
    await bufferedPositionController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Playback Reliability & Error Recovery Tests', () {
    late MusicPlayerManager manager;
    late FakeAudioPlayerEngine fakeEngine;

    final song1 = Song(
      id: 'song_1',
      title: 'Song One',
      artist: 'Artist A',
      coverUrl: '',
      audioUrl: 'http://example.com/song1.mp3',
      duration: const Duration(seconds: 180),
    );

    final song2 = Song(
      id: 'song_2',
      title: 'Song Two',
      artist: 'Artist B',
      coverUrl: '',
      audioUrl: 'https://example.com/song2.mp3',
      duration: const Duration(seconds: 200),
    );

    final song3 = Song(
      id: 'song_3',
      title: 'Song Three',
      artist: 'Artist C',
      coverUrl: '',
      audioUrl: 'https://example.com/song3.mp3',
      duration: const Duration(seconds: 220),
    );

    final song4 = Song(
      id: 'song_4',
      title: 'Song Four',
      artist: 'Artist D',
      coverUrl: '',
      audioUrl: 'https://example.com/song4.mp3',
      duration: const Duration(seconds: 240),
    );

    setUp(() {
      manager = MusicPlayerManager();
      manager.resetStateForTesting();
      fakeEngine = FakeAudioPlayerEngine();
      manager.setEngineForTesting(fakeEngine);
    });

    test('Stops previous audio before loading new audio source', () async {
      await manager.playSong(song1, newQueue: [song1, song2]);
      expect(fakeEngine.stopCallCount, greaterThanOrEqualTo(1));
      expect(manager.isPlaying, isTrue);
      expect(manager.currentSong?.id, equals('song_1'));
    });

    test('Upgrades http:// audio URLs to https://', () async {
      await manager.playSong(song1, newQueue: [song1]);
      final source = fakeEngine.lastSetSource as UriAudioSource;
      expect(source.uri.scheme, equals('https'));
      expect(source.uri.toString(), equals('https://example.com/song1.mp3'));
    });

    test(
      'Request ID cancellation: newer playSong cancels in-flight previous request',
      () async {
        final hangCompleter = Completer<void>();
        fakeEngine.setAudioSourceHangCompleter = hangCompleter;

        // Start loading song1 (which will hang in setAudioSource)
        final playSong1Future = manager.playSong(
          song1,
          newQueue: [song1, song2],
        );

        // Allow song1's playSong to progress into setAudioSource
        await Future.delayed(const Duration(milliseconds: 10));

        // Now start loading song2
        fakeEngine.setAudioSourceHangCompleter = null; // song2 won't hang
        final playSong2Future = manager.playSong(
          song2,
          newQueue: [song1, song2],
        );

        await playSong2Future;

        // Now release song1
        hangCompleter.complete();
        await playSong1Future;

        // Current song and UI state must belong to song2, not song1
        expect(manager.currentSong?.id, equals('song_2'));
        expect(manager.isPlaying, isTrue);
        expect(manager.isTransitioning, isFalse);
      },
    );

    test(
      'Timeout recovery resets isTransitioning and attempts auto-skip',
      () async {
        fakeEngine.shouldThrowOnSetAudioSource = true;

        await manager.playSong(song1, newQueue: [song1, song2]);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(manager.isTransitioning, isFalse);
        expect(manager.errorMessage, isNotNull);
        expect(manager.errorMessage, contains('Fake source load failed'));
      },
    );

    test(
      'Auto-skips up to 3 consecutive failures then stops playback gracefully',
      () async {
        fakeEngine.shouldThrowOnSetAudioSource = true;

        // Queue with 4 failing songs
        await manager.playSong(song1, newQueue: [song1, song2, song3, song4]);

        // Allow auto-skip chain to process
        await Future.delayed(const Duration(milliseconds: 100));

        // Playback must be stopped gracefully
        expect(manager.isPlaying, isFalse);
        expect(manager.isBuffering, isFalse);
        expect(manager.isTransitioning, isFalse);
      },
    );

    test('Successful play resets consecutive failure count', () async {
      // 1 failure
      fakeEngine.shouldThrowOnSetAudioSource = true;
      await manager.playSong(song1, newQueue: [song1]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.isPlaying, isFalse);

      // Next song succeeds
      fakeEngine.shouldThrowOnSetAudioSource = false;
      await manager.playSong(song2, newQueue: [song2]);

      expect(manager.isPlaying, isTrue);
      expect(manager.currentSong?.id, equals('song_2'));
    });
  });
}
