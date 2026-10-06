import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/services/jumbo_audio_handler.dart';
import 'package:jumbo_music/config/app_config.dart';

class MockJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return MockAudioPlayerPlatform(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse();
  }
}

class MockAudioPlayerPlatform extends AudioPlayerPlatform {
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  final _dataController = StreamController<PlayerDataMessage>.broadcast();

  MockAudioPlayerPlatform(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      _dataController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _eventController.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updatePosition: Duration.zero,
        updateTime: DateTime.now(),
        bufferedPosition: const Duration(seconds: 180),
        duration: const Duration(seconds: 180),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: 1,
      ),
    );
    return LoadResponse(duration: const Duration(seconds: 180));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();

  @override
  Future<AndroidEqualizerGetParametersResponse> androidEqualizerGetParameters(
    AndroidEqualizerGetParametersRequest request,
  ) async {
    return AndroidEqualizerGetParametersResponse(
      parameters: AndroidEqualizerParametersMessage(
        minDecibels: -10.0,
        maxDecibels: 10.0,
        bands: const [],
      ),
    );
  }

  @override
  Future<AndroidEqualizerBandSetGainResponse> androidEqualizerBandSetGain(
    AndroidEqualizerBandSetGainRequest request,
  ) async => AndroidEqualizerBandSetGainResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async =>
      DisposeResponse();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    JustAudioPlatform.instance = MockJustAudioPlatform();
  });

  group('JumboAudioHandler & Native Media Controls Tests', () {
    late MusicPlayerManager manager;
    late JumboAudioHandler handler;

    final testSong1 = Song(
      id: 'song_1',
      title: 'Midnight Echoes',
      artist: 'Aurora Sky',
      album: 'Cosmic Drift',
      duration: const Duration(seconds: 180),
      coverUrl: 'http://example.com/cover1.jpg',
      audioUrl: 'https://example.com/stream1.mp3',
    );

    final testSong2 = Song(
      id: 'song_2',
      title: 'Neon Horizon',
      artist: 'Synth Wave',
      album: 'Retro Future',
      duration: const Duration(seconds: 210),
      coverUrl: 'https://example.com/cover2.jpg',
      audioUrl: 'https://example.com/stream2.mp3',
    );

    setUp(() {
      manager = MusicPlayerManager();
      manager.resetStateForTesting();
      handler = JumboAudioHandler(manager);
    });

    tearDown(() {
      handler.dispose();
      AppConfig.mockUseNativeMediaControls = null;
    });

    test('Kill Switch: AppConfig default is true and mock override works', () {
      expect(AppConfig.useNativeMediaControls, isTrue);
      expect(AppConfig.isNativeMediaControlsEnabled, isTrue);

      AppConfig.mockUseNativeMediaControls = false;
      expect(AppConfig.isNativeMediaControlsEnabled, isFalse);

      AppConfig.mockUseNativeMediaControls = true;
      expect(AppConfig.isNativeMediaControlsEnabled, isTrue);
    });

    test(
      'Initial state: No song emits null MediaItem and idle PlaybackState',
      () {
        expect(handler.mediaItem.value, isNull);
        expect(
          handler.playbackState.value.processingState,
          equals(AudioProcessingState.idle),
        );
        expect(handler.playbackState.value.playing, isFalse);
      },
    );

    test(
      'MediaItem publication updates title, artist, album, duration, and upgrades http artUri to https',
      () {
        manager.setMockState(
          currentSong: testSong1,
          isPlaying: true,
          queue: [testSong1, testSong2],
        );

        final media = handler.mediaItem.value;
        expect(media, isNotNull);
        expect(media!.id, equals('song_1'));
        expect(media.title, equals('Midnight Echoes'));
        expect(media.artist, equals('Aurora Sky'));
        expect(media.album, equals('Cosmic Drift'));
        expect(media.duration, equals(const Duration(seconds: 180)));
        // http URL should be upgraded to https
        expect(
          media.artUri.toString(),
          equals('https://example.com/cover1.jpg'),
        );
      },
    );

    test('PlaybackState publishes controls and state changes', () {
      manager.setMockState(
        currentSong: testSong1,
        isPlaying: false,
        isBuffering: true,
        favoriteIds: {'song_1'},
      );

      var state = handler.playbackState.value;
      expect(state.playing, isFalse);
      expect(state.processingState, equals(AudioProcessingState.buffering));
      expect(state.controls.length, equals(5));

      // Favorite control should show favorited icon
      final favControl = state.controls[0];
      expect(favControl.androidIcon, equals('drawable/ic_action_favorite_on'));
      expect(favControl.customAction?.name, equals('toggleFavorite'));

      // Play control should be play icon when paused
      final playControl = state.controls[2];
      expect(
        playControl.androidIcon,
        equals('drawable/audio_service_play_arrow'),
      );

      // Now simulate playing state
      manager.setMockState(
        currentSong: testSong1,
        isPlaying: true,
        isBuffering: false,
        favoriteIds: {},
      );

      state = handler.playbackState.value;
      expect(state.playing, isTrue);
      expect(state.processingState, equals(AudioProcessingState.ready));

      final unfavControl = state.controls[0];
      expect(
        unfavControl.androidIcon,
        equals('drawable/ic_action_favorite_off'),
      );

      final pauseControl = state.controls[2];
      expect(pauseControl.androidIcon, equals('drawable/audio_service_pause'));
    });

    test('Playback control callbacks forward to manager', () async {
      manager.setMockState(
        currentSong: testSong1,
        isPlaying: false,
        queue: [testSong1, testSong2],
      );

      // Seek
      await handler.seek(const Duration(seconds: 45));
      expect(manager.position, equals(const Duration(seconds: 45)));

      // Reset position to zero before testing skipToNext
      await handler.seek(Duration.zero);
      expect(manager.position, equals(Duration.zero));

      // Next
      await handler.skipToNext();
      expect(manager.currentSong?.id, equals(testSong2.id));

      // Previous from beginning (< 3s) navigates to previous track
      await handler.skipToPrevious();
      expect(manager.currentSong?.id, equals(testSong1.id));
    });

    test('Custom actions toggle favorite and repeat modes', () async {
      manager.setMockState(
        currentSong: testSong1,
        isPlaying: true,
        favoriteIds: {},
      );

      expect(manager.favoriteIds.contains('song_1'), isFalse);

      // Favorite toggle
      await handler.customAction('toggleFavorite');
      expect(manager.favoriteIds.contains('song_1'), isTrue);

      await handler.customAction('toggleFavorite');
      expect(manager.favoriteIds.contains('song_1'), isFalse);

      // Repeat toggle
      expect(manager.loopMode, equals(LoopMode.off));
      await handler.customAction('toggleRepeat');
      expect(manager.loopMode, equals(LoopMode.all));
    });

    test('Standard setRepeatMode maps properly to manager', () async {
      await handler.setRepeatMode(AudioServiceRepeatMode.one);
      expect(manager.loopMode, equals(LoopMode.one));

      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      expect(manager.loopMode, equals(LoopMode.all));

      await handler.setRepeatMode(AudioServiceRepeatMode.none);
      expect(manager.loopMode, equals(LoopMode.off));
    });
  });
}
