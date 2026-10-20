import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'music_api_service.dart';
import 'privacy_security_service.dart';
import 'database_service.dart';
import 'download_service.dart';
import 'eq_presets.dart';
import 'presence_service.dart';
import 'media_session_service.dart';
import 'crash_reporting_service.dart';
import 'battery_optimization_service.dart';
import 'notification_permission_service.dart';
import 'player/web_dsp_bridge.dart';
import 'recommendation/ai_recommendation_engine.dart';

part 'player/music_player_sleep_timer.dart';
part 'player/music_player_equalizer_delegate.dart';
part 'player/music_player_library_sync.dart';
part 'player/music_player_queue_delegate.dart';

class MusicPlayerManager extends ChangeNotifier {
  static final MusicPlayerManager _instance = MusicPlayerManager._internal();
  factory MusicPlayerManager() => _instance;

  void notify() => notifyListeners();

  @visibleForTesting
  void setMockState({
    Song? currentSong,
    bool isPlaying = false,
    bool isBuffering = false,
    Set<String>? favoriteIds,
    List<Song>? queue,
    List<Song>? allSongs,
  }) {
    _currentSong = currentSong;
    if (currentSong != null) {
      _queue = queue != null
          ? SongParserUtils.deduplicateSongs(queue)
          : [currentSong];
      final curKey = SongParserUtils.songDeduplicationKey(currentSong);
      _currentIndex = _queue.indexWhere((s) => s.id == currentSong.id);
      if (_currentIndex == -1 && curKey.isNotEmpty) {
        _currentIndex = _queue.indexWhere(
          (s) => SongParserUtils.songDeduplicationKey(s) == curKey,
        );
      }
      if (_currentIndex == -1) {
        _queue.insert(0, currentSong);
        _currentIndex = 0;
      } else {
        _queue[_currentIndex] = currentSong;
      }
    } else if (queue != null) {
      _queue = SongParserUtils.deduplicateSongs(queue);
      _currentIndex = _queue.isNotEmpty ? 0 : -1;
      _currentSong = _queue.isNotEmpty ? _queue[0] : null;
    } else {
      _queue = [];
      _currentIndex = -1;
      _currentSong = null;
    }
    if (allSongs != null) {
      _allSongs = allSongs;
    }
    _isPlaying = isPlaying;
    _isBuffering = isBuffering;
    if (favoriteIds != null) {
      _favoriteIds.clear();
      _favoriteIds.addAll(favoriteIds);
    }
    notifyListeners();
  }

  @visibleForTesting
  void resetStateForTesting() {
    _currentSong = null;
    _queue = [];
    _currentIndex = -1;
    _isPlaying = false;
    _isBuffering = false;
    _favoriteIds.clear();
    _allSongs = [];
    _recentlyPlayed.clear();
    _onlineTrending = [];
    _newReleases = [];
    _isLoadingRecommendations = false;
    _infillCompleter = null;
    _isTransitioning = false;
    notifyListeners();
  }

  late final AudioPlayer _audioPlayer = AudioPlayer();
  bool get equalizerSupported => true;

  List<Song> _allSongs = [];
  List<Song> _queue = [];
  int _currentIndex = -1;
  Song? _currentSong;

  void _syncCurrentSongAndIndex() {
    if (_currentSong != null) {
      final curKey = SongParserUtils.songDeduplicationKey(_currentSong!);
      var idx = _queue.indexWhere((s) => s.id == _currentSong!.id);
      if (idx == -1) {
        idx = _queue.indexWhere(
          (s) => SongParserUtils.songDeduplicationKey(s) == curKey,
        );
      }
      if (idx != -1) {
        _queue[idx] = _currentSong!;
        _currentIndex = idx;
      } else {
        _queue.insert(0, _currentSong!);
        _currentIndex = 0;
      }
      // Guarantee queue is 100% duplicate-free
      _queue = SongParserUtils.deduplicateSongs(_queue);
      _currentIndex = _queue.indexWhere((s) => s.id == _currentSong!.id);
      if (_currentIndex == -1) {
        _currentIndex = _queue.indexWhere(
          (s) => SongParserUtils.songDeduplicationKey(s) == curKey,
        );
      }
      if (_currentIndex == -1) {
        _currentIndex = 0;
      }
    } else if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _currentSong = _queue[_currentIndex];
    }
  }

  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;

  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  double _playbackSpeed = 1.0;

  // Volume & Mute
  double _volume = 1.0;
  bool _isMuted = false;
  double _preMuteVolume = 1.0;

  // Sound Preset / Equalizer
  String _soundPreset = 'Normal';
  final List<String> soundPresets = EqPresets.names;
  bool _equalizerEnabled = true;
  List<double> _bandGains = [0.0, 0.0, 0.0, 0.0, 0.0];
  double _bassBoost = 0.0;
  double _virtualizer = 0.0;
  double _loudnessGain = 0.0;
  final Map<String, List<double>> _customPresets = {};

  // Sleep Timer
  Timer? _sleepTimer;
  Timer? _sleepTicker;
  int _sleepSecondsRemaining = 0;
  bool _sleepAfterCurrentSong = false;

  // Autoplay & Smart Infinite Radio Engine
  bool _autoplay = true;
  bool _isLoadingRecommendations = false;
  bool _isTransitioning = false;
  String? _lastInfilledSongId;
  Completer<void>? _infillCompleter;

  final Set<String> _favoriteIds = {'1', '2'};
  final List<Song> _recentlyPlayed = [];
  List<Playlist> _playlists = [];
  List<Song> _onlineTrending = [];
  List<Song> _newReleases = [];
  bool _isLoadingTrending = false;

  String? _errorMessage;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _bufferedPositionSubscription;
  StreamSubscription? _currentIndexSubscription;
  ConcatenatingAudioSource? _playlistSource;

  MusicPlayerManager._internal() {
    _init();
  }

  // Getters
  List<Song> get allSongs => _allSongs;
  List<Song> get queue => SongParserUtils.deduplicateSongs(_queue);
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _currentSong ??
      ((_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null);

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;

  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  double get playbackSpeed => _playbackSpeed;

  double get volume => _volume;
  bool get isMuted => _isMuted;
  String get soundPreset => _soundPreset;
  bool get equalizerEnabled => _equalizerEnabled;
  List<double> get bandGains => List.unmodifiable(_bandGains);
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;
  double get loudnessGain => _loudnessGain;
  Map<String, List<double>> get customPresets =>
      Map.unmodifiable(_customPresets);
  List<String> get allPresetNames => [...soundPresets, ..._customPresets.keys];

  bool get isSleepTimerActive =>
      _sleepSecondsRemaining > 0 || _sleepAfterCurrentSong;
  int get sleepSecondsRemaining => _sleepSecondsRemaining;
  bool get sleepAfterCurrentSong => _sleepAfterCurrentSong;
  String get formattedSleepTime {
    if (_sleepAfterCurrentSong) return 'End of song';
    final m = _sleepSecondsRemaining ~/ 60;
    final s = _sleepSecondsRemaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool _isQueueLocked = false;
  bool get isQueueLocked => _isQueueLocked;
  void toggleQueueLock() {
    _isQueueLocked = !_isQueueLocked;
    notifyListeners();
  }

  bool get autoplay => _autoplay;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  void toggleAutoplay() {
    _autoplay = !_autoplay;
    DatabaseService.instance.updateSetting('autoplay', _autoplay);
    if (_autoplay && currentSong != null && _queue.length < 30) {
      _infillSmartQueue(currentSong!);
    }
    notifyListeners();
  }

  Set<String> get favoriteIds => _favoriteIds;
  List<Song> get favoriteSongs =>
      _allSongs.where((s) => _favoriteIds.contains(s.id)).toList();
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Playlist> get playlists => _playlists;
  List<Playlist> get artistMixes =>
      _playlists.where((p) => p.type == PlaylistType.artistMix).toList();
  List<Playlist> get genreMixes =>
      _playlists.where((p) => p.type == PlaylistType.genreMix).toList();
  List<Playlist> get moodMixes =>
      _playlists.where((p) => p.type == PlaylistType.genreMix).toList();
  List<Playlist> get smartMixes =>
      _playlists.where((p) => p.type == PlaylistType.smartMix).toList();
  List<Playlist> get userPlaylists =>
      _playlists.where((p) => p.type == PlaylistType.custom).toList();
  List<Song> get onlineTrending => _onlineTrending;
  List<Song> get top50Songs => _allSongs.take(50).toList();
  List<Song> get newReleases => _newReleases;
  bool get isLoadingTrending => _isLoadingTrending;
  String? get errorMessage => _errorMessage;

  void _init() {
    final db = DatabaseService.instance;
    final initialOffline = [...db.downloadedSongs, ...db.favoriteSongs];

    final Set<String> seenIds = {};
    _allSongs = [];
    for (final s in initialOffline) {
      if (seenIds.add(s.id)) {
        _allSongs.add(s);
      }
    }

    _playlists = [];
    _queue = [];

    // Hydrate state from DatabaseService and listen for scope updates
    _hydrateFromDatabase();
    db.addListener(_onDatabaseChanged);
    DownloadService().addListener(_onDownloadsChanged);

    // Register lockscreen and background media action callback (Web & System)
    MediaSessionService.registerActionHandler((action, param) {
      switch (action) {
        case 'play':
          play();
          break;
        case 'pause':
          pause();
          break;
        case 'next':
          next();
          break;
        case 'previous':
          previous();
          break;
        case 'seek':
          seek(Duration(seconds: param.round()));
          break;
      }
    });

    // Listen to player state
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (state) {
        _isPlaying = state.playing;
        _isBuffering =
            (state.processingState == ProcessingState.buffering ||
                state.processingState == ProcessingState.loading) &&
            !state.playing;

        if (state.playing) {
          unawaited(BatteryOptimizationService.acquireWakeLock());
        } else {
          unawaited(BatteryOptimizationService.releaseWakeLock());
        }

        MediaSessionService.updatePlaybackState(isPlaying: state.playing);

        // Synchronize live presence to Firestore
        PresenceService.instance.updateListeningStatus(
          song: currentSong,
          isPlaying: state.playing,
          isIncognito:
              DatabaseService.instance.getSetting('incognitoMode') == true,
        );

        if (state.processingState == ProcessingState.completed &&
            !_isTransitioning) {
          _handleSongCompletion();
        }
        notifyListeners();
      },
      onError: (Object e) {
        _errorMessage = "Playback error: $e";
        _isBuffering = false;
        _isPlaying = false;
        MediaSessionService.updatePlaybackState(isPlaying: false);
        PresenceService.instance.updateListeningStatus(
          song: null,
          isPlaying: false,
        );
        notifyListeners();
      },
    );

    // Listen to position
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      if (_isBuffering && (_isPlaying || pos.inMilliseconds > 0)) {
        _isBuffering = false;
      }
      final dur = _duration.inSeconds > 0
          ? _duration.inSeconds.toDouble()
          : (currentSong != null
                ? currentSong!.duration.inSeconds.toDouble()
                : 240.0);
      MediaSessionService.updatePositionState(
        durationSeconds: dur,
        positionSeconds: pos.inSeconds.toDouble(),
        playbackRate: _playbackSpeed,
      );
      notifyListeners();
    });

    // Listen to duration
    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      if (dur != null && dur > Duration.zero) {
        _duration = dur;
        final posSec = _position.inSeconds.toDouble();
        MediaSessionService.updatePositionState(
          durationSeconds: dur.inSeconds.toDouble(),
          positionSeconds: posSec,
          playbackRate: _playbackSpeed,
        );
        notifyListeners();
      }
    });

    // Listen to buffered position
    _bufferedPositionSubscription = _audioPlayer.bufferedPositionStream.listen((
      buf,
    ) {
      _bufferedPosition = buf;
      notifyListeners();
    });

    // Listen to current sequence index (e.g. triggered by system lockscreen/notification next & prev)
    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (!kIsWeb &&
          _playlistSource != null &&
          !_isTransitioning &&
          _isPlaying &&
          index != null &&
          index >= 0 &&
          index < _queue.length &&
          index != _currentIndex) {
        // Prevent ExoPlayer timeline initialization from reverting a newly selected track back to index 0
        if (index == 0 && _currentIndex > 0 && _position.inMilliseconds < 500) {
          return;
        }

        final prevSong = _currentSong;
        _currentIndex = index;
        _currentSong = _queue[index];

        if (prevSong != null &&
            _currentSong != null &&
            prevSong.id != _currentSong!.id) {
          AiRecommendationEngine.instance.recordTransition(
            prevSong.id,
            _currentSong!.id,
          );
        }

        _recentlyPlayed.removeWhere((item) => item.id == _currentSong!.id);
        _recentlyPlayed.insert(0, _currentSong!);
        DatabaseService.instance.addHistory(_currentSong!);
        unawaited(
          DatabaseService.instance.saveLastPlayedTrack(
            _currentSong!,
            _queue,
            _position.inMilliseconds,
          ),
        );
        _updateDynamicLibrary(_currentSong!);

        if (_autoplay && _currentIndex >= _queue.length - 6) {
          _infillSmartQueue(_currentSong!);
        }

        PresenceService.instance.updateListeningStatus(
          song: _currentSong,
          isPlaying: _isPlaying,
          isIncognito:
              DatabaseService.instance.getSetting('incognitoMode') == true,
        );

        MediaSessionService.updateMetadata(
          title: _currentSong!.title,
          artist: _currentSong!.artist,
          album: _currentSong!.album.isNotEmpty
              ? _currentSong!.album
              : 'Jumbo Music',
          coverUrl: _currentSong!.coverUrl,
        );

        // In-place resolution without recursive playSong loops
        if (_currentSong != null &&
            (_currentSong!.audioUrl.trim().isEmpty ||
                _currentSong!.audioUrl.contains('preview') ||
                _currentSong!.audioUrl.contains('apple.com') ||
                (_currentSong!.duration.inSeconds > 0 &&
                    _currentSong!.duration.inSeconds < 90))) {
          unawaited(() async {
            try {
              final cleanTitle = SongParserUtils.normalizeSongTitle(
                _currentSong!.title,
              );
              final primaryArtist = _currentSong!.artist
                  .split(RegExp(r'[,&/]'))
                  .first
                  .trim();
              final matches = await MusicApiService.searchLiveSongs(
                cleanTitle.isNotEmpty && primaryArtist.isNotEmpty
                    ? '$cleanTitle $primaryArtist'
                    : cleanTitle,
                limit: 5,
              );
              final genuine = matches.firstWhere(
                (m) =>
                    m.audioUrl.isNotEmpty &&
                    !m.audioUrl.contains('apple.com') &&
                    !m.audioUrl.contains('mzstatic.com') &&
                    (m.duration.inSeconds == 0 || m.duration.inSeconds >= 90),
                orElse: () => matches.firstWhere(
                  (m) => m.audioUrl.isNotEmpty,
                  orElse: () => _currentSong!,
                ),
              );
              if (genuine.audioUrl.isNotEmpty &&
                  genuine.audioUrl != _currentSong?.audioUrl) {
                final updated = _currentSong!.copyWith(
                  audioUrl: genuine.audioUrl,
                  duration: genuine.duration.inSeconds >= 90
                      ? genuine.duration
                      : _currentSong!.duration,
                );
                final qIdx = _queue.indexWhere((s) => s.id == updated.id);
                if (qIdx != -1) _queue[qIdx] = updated;
                if (_currentIndex == qIdx) _currentSong = updated;
                notifyListeners();
              }
            } catch (_) {}
          }());
        }

        notifyListeners();
      }
    });

    fetchOnlineTrending();
    if (!kIsWeb) {
      _initAudioSession();
    }
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(true);

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _audioPlayer.setVolume(_volume * 0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (_isPlaying) {
                pause();
              }
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _audioPlayer.setVolume(_volume);
              break;
            case AudioInterruptionType.pause:
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        if (_isPlaying) {
          pause();
        }
      });
    } catch (e) {
      debugPrint('AudioSession init note: $e');
    }
  }

  void _hydrateFromDatabase() {
    final db = DatabaseService.instance;

    _autoplay = db.getSetting('autoplay', true) as bool;
    _soundPreset =
        db.getSetting('eq_preset', db.getSetting('soundPreset', 'Normal'))
            as String;
    _equalizerEnabled = db.getSetting('eq_enabled', true) as bool;
    final rawGains = db.getSetting('eq_gains', null);
    if (rawGains is List &&
        rawGains.length == 5 &&
        !identical(rawGains, _bandGains)) {
      _bandGains = rawGains.map((e) => (e as num).toDouble()).toList();
    }
    _bassBoost = (db.getSetting('eq_bass', 0.0) as num).toDouble();
    _virtualizer = (db.getSetting('eq_virtualizer', 0.0) as num).toDouble();
    _loudnessGain = (db.getSetting('eq_loudness', 0.0) as num).toDouble();
    final rawCustom = db.getSetting('eq_custom_presets', null);
    if (rawCustom is Map && !identical(rawCustom, _customPresets)) {
      _customPresets.clear();
      rawCustom.forEach((k, v) {
        if (v is List) {
          _customPresets[k.toString()] = v
              .map((e) => (e as num).toDouble())
              .toList();
        }
      });
    }
    _volume = (db.getSetting('volume', 1.0) as num).toDouble();
    _playbackSpeed = (db.getSetting('playbackSpeed', 1.0) as num).toDouble();

    _favoriteIds.clear();
    _favoriteIds.addAll(db.favoriteIds);

    _playlists.clear();
    for (final p in db.customPlaylists) {
      if (!_playlists.any((item) => item.id == p.id)) {
        _playlists.add(p);
      }
    }

    _recentlyPlayed.clear();
    for (final item in db.history) {
      if (item['song'] != null && item['song'] is Map<String, dynamic>) {
        _recentlyPlayed.add(
          Song.fromJson(item['song'] as Map<String, dynamic>),
        );
      }
    }

    final downloaded = db.downloadedSongs;
    if (downloaded.isNotEmpty) {
      final Set<String> ids = _allSongs.map((s) => s.id).toSet();
      for (final dl in downloaded) {
        if (!ids.contains(dl.id)) {
          _allSongs.insert(0, dl);
        }
      }
    }

    // Restore last played track and queue on cold startup if player is idle
    if (_currentSong == null && !_isPlaying) {
      final lastPlayed = db.lastPlayedSong;
      if (lastPlayed != null) {
        _currentSong = lastPlayed;
        final savedQueue = db.lastPlayedQueue;
        if (savedQueue.isNotEmpty) {
          _queue = SongParserUtils.deduplicateSongs(savedQueue);
        } else if (_recentlyPlayed.isNotEmpty) {
          _queue = SongParserUtils.deduplicateSongs(_recentlyPlayed);
        } else {
          _queue = [lastPlayed];
        }
        _queue = SongParserUtils.deduplicateSongs(_queue);
        final lastKey = SongParserUtils.songDeduplicationKey(lastPlayed);
        var idx = _queue.indexWhere((s) => s.id == lastPlayed.id);
        if (idx == -1 && lastKey.isNotEmpty) {
          idx = _queue.indexWhere(
            (s) => SongParserUtils.songDeduplicationKey(s) == lastKey,
          );
        }
        if (idx != -1) {
          _queue[idx] = lastPlayed;
          _currentIndex = idx;
        } else {
          _queue.insert(0, lastPlayed);
          _currentIndex = 0;
        }
        _isPlaying = false;
        _duration = lastPlayed.duration;
        _position = Duration(milliseconds: db.lastPlayedPositionMs);

        MediaSessionService.updateMetadata(
          title: lastPlayed.title,
          artist: lastPlayed.artist,
          album: lastPlayed.album.isNotEmpty ? lastPlayed.album : 'Jumbo Music',
          coverUrl: lastPlayed.coverUrl,
        );
        MediaSessionService.updatePlaybackState(isPlaying: false);
      }
    }

    _syncCurrentSongAndIndex();
  }

  Future<void> fetchOnlineTrending() async {
    _isLoadingTrending = true;
    notifyListeners();

    try {
      final indiaTop50Result = await MusicApiService.fetchPlaylist(
        '1134543272',
      );
      final indiaSongs = (indiaTop50Result['songs'] as List<Song>?) ?? [];

      final trendingResult = await MusicApiService.fetchPlaylist('110858205');
      final trendingSongs = (trendingResult['songs'] as List<Song>?) ?? [];

      final indieResult = await MusicApiService.fetchPlaylist('82914609');
      final indieSongs = (indieResult['songs'] as List<Song>?) ?? [];

      final duetsResult = await MusicApiService.fetchPlaylist('159470188');
      final duetsSongs = (duetsResult['songs'] as List<Song>?) ?? [];

      try {
        final fresh = await MusicApiService.fetchNewReleases(limit: 30);
        if (fresh.isNotEmpty) {
          _newReleases = fresh;
        }
      } catch (error) {
        CrashReportingService.swallow(error, 'music_player_manager.dart:357');
      }

      final List<Playlist> livePlaylists = [];
      if (indiaSongs.isNotEmpty) {
        livePlaylists.add(
          Playlist(
            id: '1134543272',
            title: indiaTop50Result['name'] ?? 'India Superhits Top 50',
            description:
                'Top trending 50 chartbusters across India (320 kbps Studio)',
            coverUrl:
                (indiaTop50Result['coverUrl'] as String?)?.isNotEmpty == true
                ? indiaTop50Result['coverUrl']
                : (indiaSongs.first.coverUrl),
            songIds: indiaSongs.map((s) => s.id).toList(),
          ),
        );
      }

      if (trendingSongs.isNotEmpty) {
        livePlaylists.add(
          Playlist(
            id: '110858205',
            title: trendingResult['name'] ?? 'Trending Today',
            description: 'Today\'s hottest streaming songs live',
            coverUrl:
                (trendingResult['coverUrl'] as String?)?.isNotEmpty == true
                ? trendingResult['coverUrl']
                : (trendingSongs.first.coverUrl),
            songIds: trendingSongs.map((s) => s.id).toList(),
          ),
        );
      }

      if (indieSongs.isNotEmpty) {
        livePlaylists.add(
          Playlist(
            id: '82914609',
            title: indieResult['name'] ?? 'Best of Indie',
            description: 'Finest independent indie & acoustic releases',
            coverUrl: (indieResult['coverUrl'] as String?)?.isNotEmpty == true
                ? indieResult['coverUrl']
                : (indieSongs.first.coverUrl),
            songIds: indieSongs.map((s) => s.id).toList(),
          ),
        );
      }

      if (duetsSongs.isNotEmpty) {
        livePlaylists.add(
          Playlist(
            id: '159470188',
            title: duetsResult['name'] ?? '90s Evergreen Duets',
            description: 'Golden era Bollywood duets & romantic memories',
            coverUrl: (duetsResult['coverUrl'] as String?)?.isNotEmpty == true
                ? duetsResult['coverUrl']
                : (duetsSongs.first.coverUrl),
            songIds: duetsSongs.map((s) => s.id).toList(),
          ),
        );
      }

      final allLiveSongs = [
        ...indiaSongs,
        ...trendingSongs,
        ...indieSongs,
        ...duetsSongs,
      ];

      if (allLiveSongs.isNotEmpty) {
        _onlineTrending = allLiveSongs;

        final Set<String> existingIds = _allSongs.map((s) => s.id).toSet();
        final List<Song> newUnique = allLiveSongs
            .where((s) => !existingIds.contains(s.id))
            .toList();
        _allSongs = [...newUnique, ..._allSongs];
        _syncCurrentSongAndIndex();
      }
    } catch (error) {
      CrashReportingService.swallow(error, 'music_player_manager.dart:441');
    }

    _isLoadingTrending = false;
    notifyListeners();
  }

  /// Plays a song selected from Search and automatically builds a focused,
  /// 50-60 song smart queue tailored strictly to that song's era, artist, and genre,
  /// incorporating user's favorites, playlists, feed, and search history via AI recommendation engine.
  Future<void> playSongFromSearch(
    Song song, {
    List<Song>? searchResults,
  }) async {
    final seedLang = MusicApiService.detectSongLanguage(song);
    final seedEra = MusicTagClassifier.detectSongEra(song);
    final immediateCandidates = <Song>[];
    final seenIds = <String>{song.id};
    final seenKeys = <String>{SongParserUtils.songDeduplicationKey(song)};

    void tryAddCandidate(Song candidate) {
      if (candidate.audioUrl.trim().isEmpty) return;
      if (candidate.audioUrl.contains('apple.com') ||
          candidate.audioUrl.contains('mzstatic.com') ||
          candidate.audioUrl.contains('preview')) {
        return;
      }
      if (candidate.duration.inSeconds > 0 &&
          candidate.duration.inSeconds < 75) {
        return;
      }
      // Strict language match
      if (MusicApiService.detectSongLanguage(candidate) != seedLang) {
        return;
      }
      if (seedLang != 'English' &&
          MusicTagClassifier.isEnglishSong(candidate)) {
        return;
      }
      if (seedLang == 'English' &&
          !MusicTagClassifier.isEnglishSong(candidate)) {
        return;
      }
      // Strict era match
      if (MusicTagClassifier.detectSongEra(candidate) != seedEra) {
        return;
      }

      final key = SongParserUtils.songDeduplicationKey(candidate);
      if (seenIds.add(candidate.id) && seenKeys.add(key)) {
        immediateCandidates.add(candidate);
      }
    }

    if (searchResults != null) {
      for (final s in searchResults) {
        tryAddCandidate(s);
      }
    }

    // Proactively fetch smart recommendations tailored for this exact seed song & artist
    try {
      final liveRecs = await MusicApiService.fetchSmartRecommendations(
        song,
        limit: 30,
      );
      for (final r in liveRecs) {
        tryAddCandidate(r);
      }
    } catch (_) {}

    // If candidate pool has few tracks, proactively fetch live era-matching songs
    if (immediateCandidates.length < 15) {
      final targeted = AiRecommendationEngine.getEraTargetedQueries(
        seedLang,
        seedEra,
        song,
      );
      for (final q in targeted) {
        if (immediateCandidates.length >= 25) break;
        try {
          final liveMatches = await MusicApiService.searchLiveSongs(
            q,
            limit: 10,
          );
          for (final lm in liveMatches) {
            tryAddCandidate(lm);
          }
        } catch (_) {}
      }
    }

    immediateCandidates.sort((a, b) {
      final scoreA = AiRecommendationEngine.instance.scoreCandidate(song, a);
      final scoreB = AiRecommendationEngine.instance.scoreCandidate(song, b);
      return scoreB.compareTo(scoreA);
    });

    final initialQueue = [song, ...immediateCandidates.take(30)];
    await playSong(song, newQueue: initialQueue);

    unawaited(BatteryOptimizationService.instance.promptOptimizationIfNeeded());
    _infillSmartQueue(song, targetQueueSize: 60);
  }

  Future<void> playSong(
    Song song, {
    List<Song>? newQueue,
    List<Song>? playlistContext,
  }) async {
    _isTransitioning = true;
    _errorMessage = null;

    // Immediately pause/silence previous audio to prevent ghost playback and overlap
    if (_audioPlayer.playing || _isPlaying) {
      try {
        await _audioPlayer.pause();
      } catch (_) {}
    }

    // 1. Pre-resolve full live streaming URL if empty, Apple preview (30s), or short clip (< 90s)
    Song resolvedSong = song;
    final isDl = DownloadService().isDownloaded(resolvedSong.id);
    final offlineUri = await DownloadService().playableUriFor(
      resolvedSong.id,
      title: resolvedSong.title,
    );

    final bool isApplePreview =
        resolvedSong.audioUrl.contains('apple.com') ||
        resolvedSong.audioUrl.contains('mzstatic.com') ||
        resolvedSong.audioUrl.contains('preview');
    final bool isShortClip =
        resolvedSong.duration.inSeconds > 0 &&
        resolvedSong.duration.inSeconds < 90;

    if (offlineUri == null &&
        !isDl &&
        (resolvedSong.audioUrl.trim().isEmpty ||
            isApplePreview ||
            isShortClip) &&
        resolvedSong.title.isNotEmpty) {
      try {
        debugPrint(
          '[Playback] Pre-resolving full live audioUrl for "${resolvedSong.title}"...',
        );
        final cleanTitle = SongParserUtils.normalizeSongTitle(
          resolvedSong.title,
        );
        final primaryArtist = resolvedSong.artist
            .split(RegExp(r'[,&/]'))
            .first
            .trim();

        List<Song> freshMatches = [];
        // Strategy 1: Normalized clean title + primary artist
        if (cleanTitle.isNotEmpty && primaryArtist.isNotEmpty) {
          freshMatches = await MusicApiService.searchLiveSongs(
            '$cleanTitle $primaryArtist',
            limit: 6,
          );
        }

        // Strategy 2: Clean title alone if Strategy 1 found no full track
        final bool hasGenuineInFresh = freshMatches.any(
          (m) =>
              m.audioUrl.isNotEmpty &&
              !m.audioUrl.contains('apple.com') &&
              !m.audioUrl.contains('mzstatic.com') &&
              (m.duration.inSeconds == 0 || m.duration.inSeconds >= 90),
        );
        if (!hasGenuineInFresh && cleanTitle.isNotEmpty) {
          final titleMatches = await MusicApiService.searchLiveSongs(
            cleanTitle,
            limit: 6,
          );
          if (titleMatches.isNotEmpty) {
            freshMatches = [...titleMatches, ...freshMatches];
          }
        }

        // Strategy 3: Original raw query if still needed
        if (freshMatches.isEmpty) {
          freshMatches = await MusicApiService.searchLiveSongs(
            '${resolvedSong.title} ${resolvedSong.artist}',
            limit: 5,
          );
        }

        // Prioritize full-length (>= 90s), non-preview stream
        final genuineMatch = freshMatches.firstWhere(
          (m) =>
              m.audioUrl.isNotEmpty &&
              !m.audioUrl.contains('apple.com') &&
              !m.audioUrl.contains('mzstatic.com') &&
              (m.duration.inSeconds == 0 || m.duration.inSeconds >= 90),
          orElse: () => freshMatches.firstWhere(
            (m) => m.audioUrl.isNotEmpty,
            orElse: () => resolvedSong,
          ),
        );

        if (genuineMatch.audioUrl.isNotEmpty) {
          resolvedSong = resolvedSong.copyWith(
            audioUrl: genuineMatch.audioUrl,
            duration: genuineMatch.duration.inSeconds >= 90
                ? genuineMatch.duration
                : (resolvedSong.duration.inSeconds >= 90
                      ? resolvedSong.duration
                      : genuineMatch.duration),
          );
        }
      } catch (e) {
        debugPrint('[Playback] Pre-resolve error: $e');
      }
    }

    final prevSong = _currentSong;
    _currentSong = resolvedSong;

    if (prevSong != null && resolvedSong.id != prevSong.id) {
      AiRecommendationEngine.instance.recordTransition(
        prevSong.id,
        resolvedSong.id,
      );
    }

    if (!_allSongs.any((s) => s.id == resolvedSong.id)) {
      _allSongs.insert(0, resolvedSong);
    }

    final queueToUse = newQueue ?? playlistContext;
    final rKey = SongParserUtils.songDeduplicationKey(resolvedSong);
    if (queueToUse != null && queueToUse.isNotEmpty) {
      _queue = SongParserUtils.deduplicateSongs(queueToUse);
      var idx = _queue.indexWhere((s) => s.id == resolvedSong.id);
      if (idx == -1 && rKey.isNotEmpty) {
        idx = _queue.indexWhere(
          (s) => SongParserUtils.songDeduplicationKey(s) == rKey,
        );
      }
      if (idx != -1) {
        _queue[idx] = resolvedSong;
        _currentIndex = idx;
      } else {
        _queue.insert(0, resolvedSong);
        _currentIndex = 0;
      }
    } else {
      _queue = SongParserUtils.deduplicateSongs(_queue);
      var existingIdx = _queue.indexWhere((s) => s.id == resolvedSong.id);
      if (existingIdx == -1 && rKey.isNotEmpty) {
        existingIdx = _queue.indexWhere(
          (s) => SongParserUtils.songDeduplicationKey(s) == rKey,
        );
      }
      if (existingIdx != -1) {
        _queue[existingIdx] = resolvedSong;
        _currentIndex = existingIdx;
      } else {
        final seedCandidates = <Song>[resolvedSong];
        final seen = <String>{resolvedSong.id};
        final seenKeys = <String>{
          SongParserUtils.songDeduplicationKey(resolvedSong),
        };
        final rLang = MusicApiService.detectSongLanguage(resolvedSong);
        final rEra = MusicTagClassifier.detectSongEra(resolvedSong);

        void addSeedFrom(List<Song> source) {
          for (final s in source) {
            if (s.id == resolvedSong.id) continue;
            final key = SongParserUtils.songDeduplicationKey(s);
            if (seenKeys.contains(key)) continue;
            if (s.audioUrl.trim().isEmpty) continue;
            if (MusicApiService.detectSongLanguage(s) != rLang) continue;
            if (rLang != 'English' && MusicTagClassifier.isEnglishSong(s)) {
              continue;
            }
            if (rLang == 'English' && !MusicTagClassifier.isEnglishSong(s)) {
              continue;
            }
            if (MusicTagClassifier.detectSongEra(s) != rEra) continue;
            if (seen.add(s.id) && seenKeys.add(key)) {
              seedCandidates.add(s);
            }
          }
        }

        addSeedFrom(_allSongs);
        addSeedFrom(_onlineTrending);
        addSeedFrom(_newReleases);

        _queue = seedCandidates;
        _currentIndex = 0;
      }
    }

    // Filter out invalid/empty/preview audio tracks only for dynamic auto-infilled queues.
    // If queue is provided by caller (playlistContext or newQueue), preserve the full playlist!
    if (playlistContext == null && newQueue == null) {
      final seedLang = MusicApiService.detectSongLanguage(resolvedSong);
      final seedEra = MusicTagClassifier.detectSongEra(resolvedSong);
      _queue = _queue.where((s) {
        if (s.id == resolvedSong.id) return true;
        if (s.audioUrl.trim().isEmpty) return false;
        if (s.audioUrl.contains('apple.com') ||
            s.audioUrl.contains('mzstatic.com') ||
            s.audioUrl.contains('preview')) {
          return false;
        }
        if (s.duration.inSeconds > 0 && s.duration.inSeconds < 75) {
          return false;
        }
        if (MusicApiService.detectSongLanguage(s) != seedLang) return false;
        if (seedLang != 'English' && MusicTagClassifier.isEnglishSong(s)) {
          return false;
        }
        if (seedLang == 'English' && !MusicTagClassifier.isEnglishSong(s)) {
          return false;
        }
        if (MusicTagClassifier.detectSongEra(s) != seedEra) return false;
        return s.audioUrl.trim().isNotEmpty ||
            DownloadService().isDownloaded(s.id);
      }).toList();
    }

    final resolvedKey = SongParserUtils.songDeduplicationKey(resolvedSong);
    _queue = SongParserUtils.deduplicateSongs(_queue);
    var targetIdx = _queue.indexWhere((s) => s.id == resolvedSong.id);
    if (targetIdx == -1) {
      targetIdx = _queue.indexWhere(
        (s) => SongParserUtils.songDeduplicationKey(s) == resolvedKey,
      );
    }
    if (targetIdx != -1) {
      _queue[targetIdx] = resolvedSong;
      _currentIndex = targetIdx;
    } else {
      _queue.insert(0, resolvedSong);
      _currentIndex = 0;
    }
    _queue = SongParserUtils.deduplicateSongs(_queue);

    _syncCurrentSongAndIndex();

    _recentlyPlayed.removeWhere((item) => item.id == resolvedSong.id);
    _recentlyPlayed.insert(0, resolvedSong);
    DatabaseService.instance.addHistory(resolvedSong);
    unawaited(
      DatabaseService.instance.saveLastPlayedTrack(
        resolvedSong,
        _queue,
        _position.inMilliseconds,
      ),
    );

    _updateDynamicLibrary(resolvedSong);

    _isPlaying = true;
    _isBuffering = true;
    _position = Duration.zero;
    _duration = resolvedSong.duration;
    notifyListeners();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(
        NotificationPermissionService.instance
            .requestNotificationPermissionIfNeeded(),
      );
      BatteryOptimizationService.instance.checkOptimizationStatus();
    }

    try {
      MediaSessionService.updateMetadata(
        title: resolvedSong.title.isNotEmpty
            ? resolvedSong.title
            : 'Unknown Title',
        artist: resolvedSong.artist.isNotEmpty
            ? resolvedSong.artist
            : 'Unknown Artist',
        album: resolvedSong.album.isNotEmpty
            ? resolvedSong.album
            : 'Jumbo Music',
        coverUrl: resolvedSong.coverUrl,
      );
      MediaSessionService.updatePlaybackState(isPlaying: true);
      MediaSessionService.updatePositionState(
        durationSeconds: resolvedSong.duration.inSeconds > 0
            ? resolvedSong.duration.inSeconds.toDouble()
            : 240.0,
        positionSeconds: 0.0,
        playbackRate: _playbackSpeed,
      );

      final Uri sourceUri;
      if (offlineUri != null) {
        sourceUri = offlineUri;
        debugPrint(
          '[Playback] CHOSEN SOURCE URI: $sourceUri (local offline copy)',
        );
      } else {
        if (isDl) {
          debugPrint(
            '[Playback] NOTICE: "${resolvedSong.title}" is in downloaded list but local file not found. Falling back to stream URI.',
          );
        }
        sourceUri = Uri.parse(resolvedSong.audioUrl);
        debugPrint('[Playback] CHOSEN SOURCE URI: $sourceUri (network stream)');
      }

      // Build playlist audio sources for the entire queue with MediaItem metadata.
      // This enables phone notification & lock screen playback controls: previous, play/pause, next, seekbar.
      MediaItem? currentMediaItem;
      final List<AudioSource> audioSources = [];
      final queueSnapshot = List<Song>.from(_queue);
      for (int i = 0; i < queueSnapshot.length; i++) {
        final qSong = queueSnapshot[i];
        final qCover = qSong.coverUrl.trim();
        final qSecureCover = qCover.startsWith('http://')
            ? qCover.replaceFirst('http://', 'https://')
            : qCover;
        final Uri? qArtUri;
        if (qSecureCover.startsWith('file://')) {
          qArtUri = Uri.parse(qSecureCover);
        } else if (qSecureCover.startsWith('/') &&
            !qSecureCover.startsWith('//')) {
          qArtUri = Uri.file(qSecureCover);
        } else if (qSecureCover.startsWith('https://') ||
            qSecureCover.startsWith('http://')) {
          final parsed = Uri.tryParse(qSecureCover);
          qArtUri =
              (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty)
              ? parsed
              : null;
        } else {
          qArtUri = null;
        }

        final qMediaItem = MediaItem(
          id: qSong.id,
          album: qSong.album.isNotEmpty ? qSong.album : 'Jumbo Music',
          title: qSong.title.isNotEmpty ? qSong.title : 'Unknown Title',
          artist: qSong.artist.isNotEmpty ? qSong.artist : 'Unknown Artist',
          artUri: qArtUri,
          duration: qSong.duration.inSeconds > 0 ? qSong.duration : null,
          playable: true,
          displayTitle: qSong.title.isNotEmpty ? qSong.title : 'Unknown Title',
          displaySubtitle: qSong.artist.isNotEmpty
              ? qSong.artist
              : 'Unknown Artist',
          displayDescription: qSong.album.isNotEmpty
              ? qSong.album
              : 'Jumbo Music',
        );

        if (i == _currentIndex) {
          currentMediaItem = qMediaItem;
        }

        final Uri qUri;
        if (i == _currentIndex) {
          qUri = sourceUri;
        } else {
          final isQdl = DownloadService().isDownloaded(qSong.id);
          final offlineQUri = isQdl
              ? await DownloadService().playableUriFor(
                  qSong.id,
                  title: qSong.title,
                )
              : null;
          qUri =
              offlineQUri ??
              Uri.parse(
                qSong.audioUrl.isNotEmpty
                    ? qSong.audioUrl
                    : sourceUri.toString(),
              );
        }

        audioSources.add(AudioSource.uri(qUri, tag: qMediaItem));
      }

      if (sourceUri.toString().trim().isEmpty) {
        throw Exception(
          "Audio stream URL is empty for '${resolvedSong.title}'",
        );
      }

      if (kIsWeb) {
        _playlistSource = null;
        try {
          await _audioPlayer.stop();
        } catch (_) {}
        await _audioPlayer.setAudioSource(
          AudioSource.uri(sourceUri, tag: currentMediaItem),
          initialPosition: Duration.zero,
          preload: true,
        );
      } else {
        _playlistSource = ConcatenatingAudioSource(
          children: audioSources,
          useLazyPreparation: true,
        );

        await _audioPlayer.setAudioSource(
          _playlistSource!,
          initialIndex: _currentIndex,
          initialPosition: Duration.zero,
          preload: true,
        );
      }

      try {
        await _audioPlayer.setSpeed(_playbackSpeed);
      } catch (_) {}
      try {
        await _audioPlayer.setVolume(_volume);
      } catch (_) {}
      try {
        await _audioPlayer.setLoopMode(
          _loopMode == LoopMode.one ? LoopMode.one : LoopMode.off,
        );
      } catch (_) {}
      _startPlayback();
      _isPlaying = true;
      _isBuffering = false;

      if (_autoplay && _queue.length < 30) {
        unawaited(_infillSmartQueue(resolvedSong, targetQueueSize: 50));
      }
    } catch (e, stack) {
      // 10/10 Resilience: Attempt automatic stream auto-heal if online URL was expired or broken
      final isDl = DownloadService().isDownloaded(resolvedSong.id);
      if (!isDl && resolvedSong.title.isNotEmpty) {
        try {
          debugPrint(
            '[Playback] Attempting stream auto-heal for "${resolvedSong.title}"...',
          );
          final cleanTitle = SongParserUtils.normalizeSongTitle(
            resolvedSong.title,
          );
          List<Song> healedSongs = [];
          if (cleanTitle.isNotEmpty) {
            healedSongs = await MusicApiService.searchLiveSongs(
              cleanTitle,
              limit: 5,
            );
          }
          if (healedSongs.isEmpty) {
            healedSongs = await MusicApiService.searchLiveSongs(
              '${resolvedSong.title} ${resolvedSong.artist}',
              limit: 5,
            );
          }
          if (healedSongs.isNotEmpty &&
              healedSongs.first.audioUrl.isNotEmpty &&
              healedSongs.first.audioUrl != resolvedSong.audioUrl) {
            final freshTrack = resolvedSong.copyWith(
              audioUrl: healedSongs.first.audioUrl,
            );
            final idx = _queue.indexWhere((s) => s.id == resolvedSong.id);
            if (idx != -1) _queue[idx] = freshTrack;

            // Rebuild ConcatenatingAudioSource preserving the full queue for lockscreen next/prev
            final List<AudioSource> healedSources = [];
            MediaItem? healedCurrentItem;
            final healedQueueSnapshot = List<Song>.from(_queue);
            for (int i = 0; i < healedQueueSnapshot.length; i++) {
              final s = healedQueueSnapshot[i];
              final sCover = s.coverUrl.trim();
              final sSecureCover = sCover.startsWith('http://')
                  ? sCover.replaceFirst('http://', 'https://')
                  : sCover;
              final Uri? sArtUri;
              if (sSecureCover.startsWith('file://')) {
                sArtUri = Uri.parse(sSecureCover);
              } else if (sSecureCover.startsWith('/') &&
                  !sSecureCover.startsWith('//')) {
                sArtUri = Uri.file(sSecureCover);
              } else if (sSecureCover.startsWith('https://') ||
                  sSecureCover.startsWith('http://')) {
                final parsed = Uri.tryParse(sSecureCover);
                sArtUri =
                    (parsed != null &&
                        parsed.hasScheme &&
                        parsed.host.isNotEmpty)
                    ? parsed
                    : null;
              } else {
                sArtUri = null;
              }

              final mItem = MediaItem(
                id: s.id,
                album: s.album.isNotEmpty ? s.album : 'Jumbo Music',
                title: s.title.isNotEmpty ? s.title : 'Unknown Title',
                artist: s.artist.isNotEmpty ? s.artist : 'Unknown Artist',
                artUri: sArtUri,
                duration: s.duration.inSeconds > 0 ? s.duration : null,
                playable: true,
                displayTitle: s.title.isNotEmpty ? s.title : 'Unknown Title',
                displaySubtitle: s.artist.isNotEmpty
                    ? s.artist
                    : 'Unknown Artist',
                displayDescription: s.album.isNotEmpty
                    ? s.album
                    : 'Jumbo Music',
              );
              if (i == _currentIndex) {
                healedCurrentItem = mItem;
              }
              healedSources.add(
                AudioSource.uri(
                  Uri.parse(
                    s.audioUrl.isNotEmpty ? s.audioUrl : freshTrack.audioUrl,
                  ),
                  tag: mItem,
                ),
              );
            }

            if (kIsWeb) {
              _playlistSource = null;
              try {
                await _audioPlayer.stop();
              } catch (_) {}
              await _audioPlayer.setAudioSource(
                AudioSource.uri(
                  Uri.parse(freshTrack.audioUrl),
                  tag: healedCurrentItem,
                ),
                initialPosition: Duration.zero,
                preload: true,
              );
            } else {
              _playlistSource = ConcatenatingAudioSource(
                children: healedSources,
                useLazyPreparation: true,
              );

              await _audioPlayer.setAudioSource(
                _playlistSource!,
                initialIndex: _currentIndex,
                initialPosition: Duration.zero,
                preload: true,
              );
            }
            try {
              await _audioPlayer.setSpeed(_playbackSpeed);
            } catch (_) {}
            try {
              await _audioPlayer.setVolume(_volume);
            } catch (_) {}
            _startPlayback();
            _isPlaying = true;
            _isBuffering = false;
            _errorMessage = null;
            _isTransitioning = false;
            notifyListeners();
            return;
          }
        } catch (healError) {
          debugPrint('[Playback] Auto-heal failed: $healError');
        }
      }

      if (isDl &&
          await DownloadService().playableUriFor(
                resolvedSong.id,
                title: resolvedSong.title,
              ) ==
              null) {
        _errorMessage =
            "Offline audio file for '${resolvedSong.title}' was not found in local storage. Connect to internet to stream.";
      } else {
        _errorMessage = "Unable to play audio: $e";
      }
      debugPrint('[Playback] FAILED: $_errorMessage (original: $e)\n$stack');
      _isBuffering = false;
      _isPlaying = false;
      try {
        await _audioPlayer.stop();
      } catch (_) {}
      MediaSessionService.updatePlaybackState(isPlaying: false);
    } finally {
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// Skips directly to a specific song in the Up Next queue.
  /// Preserves the existing queue and prevents recommendations from re-shuffling.
  Future<void> skipToQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex) {
      if (_queue.length <= 1 && _loopMode != LoopMode.one) {
        await next();
        return;
      }
      if (_isPlaying) return;
    }

    final prevSong = _currentSong;
    final targetSong = _queue[index];

    if (prevSong != null && targetSong.id != prevSong.id) {
      AiRecommendationEngine.instance.recordTransition(
        prevSong.id,
        targetSong.id,
      );
    }

    await playSong(targetSong, newQueue: List.from(_queue));
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    final targetIndex = (initialIndex >= 0 && initialIndex < songs.length)
        ? initialIndex
        : 0;
    await playSong(songs[targetIndex], newQueue: List.from(songs));
  }

  void _startPlayback() {
    unawaited(BatteryOptimizationService.acquireWakeLock());
    unawaited(
      _audioPlayer.play().catchError((Object e) {
        _errorMessage = 'Playback error: $e';
        _isPlaying = false;
        _isBuffering = false;
        unawaited(BatteryOptimizationService.releaseWakeLock());
        notifyListeners();
      }),
    );
  }

  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
    MediaSessionService.updatePlaybackState(isPlaying: false);
    unawaited(BatteryOptimizationService.releaseWakeLock());
    await _audioPlayer.pause();
    if (_currentSong != null) {
      unawaited(
        DatabaseService.instance.saveLastPlayedTrack(
          _currentSong!,
          _queue,
          _position.inMilliseconds,
        ),
      );
    }
  }

  Future<void> play() async {
    if (currentSong == null) {
      final db = DatabaseService.instance;
      if (db.lastPlayedSong != null) {
        await playSong(db.lastPlayedSong!);
        return;
      } else if (db.historySongs.isNotEmpty) {
        await playSong(db.historySongs.first);
        return;
      } else if (_allSongs.isNotEmpty) {
        await playSong(_allSongs[0]);
        return;
      }
      return;
    }
    if (_audioPlayer.audioSource == null) {
      await playSong(currentSong!, newQueue: _queue.isNotEmpty ? _queue : null);
      return;
    }
    _isPlaying = true;
    notifyListeners();
    MediaSessionService.updatePlaybackState(isPlaying: true);
    unawaited(BatteryOptimizationService.acquireWakeLock());
    await _audioPlayer.play();
  }

  Future<void> togglePlay() async {
    if (currentSong == null) {
      final db = DatabaseService.instance;
      if (db.historySongs.isNotEmpty) {
        await playSong(db.historySongs.first);
        return;
      } else if (_allSongs.isNotEmpty) {
        await playSong(_allSongs[0]);
        return;
      }
      return;
    }

    try {
      if (_isPlaying || _audioPlayer.playing) {
        _isPlaying = false;
        notifyListeners();
        MediaSessionService.updatePlaybackState(isPlaying: false);
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.audioSource == null) {
          await playSong(
            currentSong!,
            newQueue: _queue.isNotEmpty ? _queue : null,
          );
          return;
        }
        _isPlaying = true;
        notifyListeners();
        MediaSessionService.updatePlaybackState(isPlaying: true);
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        _startPlayback();
      }
    } catch (e) {
      _errorMessage = "Playback toggle error: $e";
      _isPlaying = _audioPlayer.playing;
      notifyListeners();
    }
  }

  /// A fallback track from library / trending / offline when queue has no alternative song
  Song? _findDistinctNextTrack() {
    final curId = currentSong?.id;
    final curKey = currentSong != null
        ? SongParserUtils.songDeduplicationKey(currentSong!)
        : null;
    final curLang = currentSong != null
        ? MusicApiService.detectSongLanguage(currentSong!)
        : null;
    final curEra = currentSong != null
        ? MusicTagClassifier.detectSongEra(currentSong!)
        : null;

    final candidatePool = <Song>[];
    final seen = <String>{};
    if (curId != null) seen.add(curId);
    final seenKeys = <String>{};
    if (curKey != null && curKey.isNotEmpty) seenKeys.add(curKey);

    void addFrom(List<Song> source) {
      for (final s in List<Song>.from(source)) {
        if (s.id == curId) continue;
        final k = SongParserUtils.songDeduplicationKey(s);
        if (curKey != null && k == curKey) {
          continue;
        }
        if (s.audioUrl.trim().isEmpty &&
            !DownloadService().isDownloaded(s.id)) {
          continue;
        }
        if (curLang != null &&
            MusicApiService.detectSongLanguage(s) != curLang) {
          continue;
        }
        if (curLang != null) {
          if (curLang != 'English' && MusicTagClassifier.isEnglishSong(s)) {
            continue;
          }
          if (curLang == 'English' && !MusicTagClassifier.isEnglishSong(s)) {
            continue;
          }
        }
        if (curEra != null && MusicTagClassifier.detectSongEra(s) != curEra) {
          continue;
        }
        if (seen.add(s.id) && seenKeys.add(k)) {
          candidatePool.add(s);
        }
      }
    }

    addFrom(_allSongs);
    addFrom(_onlineTrending);
    addFrom(_newReleases);
    addFrom(_recentlyPlayed);
    final db = DatabaseService.instance;
    addFrom(db.historySongs);
    addFrom(db.favoriteSongs);
    for (final pl in db.playlists) {
      addFrom(pl.songs);
    }
    addFrom(DownloadService().downloadedSongs);

    if (candidatePool.isNotEmpty) {
      candidatePool.shuffle();
      return candidatePool.first;
    }

    return null;
  }

  Future<void> next({bool fromCompletion = false}) async {
    if (_isTransitioning && !fromCompletion) return;
    _isTransitioning = true;

    try {
      final prevSong = currentSong;
      if (prevSong != null && _position.inSeconds < 25) {
        AiRecommendationEngine.instance.recordSkip(prevSong.id);
      }

      if (_queue.isEmpty) {
        final fallback = _findDistinctNextTrack();
        if (fallback != null) {
          _queue = [fallback];
          await playSong(fallback);
        }
        return;
      }

      if (_autoplay &&
          currentSong != null &&
          _currentIndex >= _queue.length - 6) {
        _infillSmartQueue(currentSong!);
      }

      final curKey = currentSong != null
          ? SongParserUtils.songDeduplicationKey(currentSong!)
          : '';

      if (_isShuffle && _queue.length > 1) {
        final List<int> candidates = [];
        for (int i = 0; i < _queue.length; i++) {
          final track = _queue[i];
          final key = SongParserUtils.songDeduplicationKey(track);
          if (i != _currentIndex &&
              track.id != currentSong?.id &&
              (curKey.isEmpty || key != curKey)) {
            candidates.add(i);
          }
        }
        if (candidates.isNotEmpty) {
          candidates.shuffle();
          await skipToQueueIndex(candidates.first);
          return;
        }
      }

      // Look ahead in queue for the next distinct track
      int foundIndex = -1;
      for (int i = _currentIndex + 1; i < _queue.length; i++) {
        final s = _queue[i];
        final key = SongParserUtils.songDeduplicationKey(s);
        if (s.id != currentSong?.id && (curKey.isEmpty || key != curKey)) {
          foundIndex = i;
          break;
        }
      }

      if (foundIndex != -1) {
        await skipToQueueIndex(foundIndex);
        return;
      }

      // Queue ahead is exhausted of distinct tracks. Try autoplay infill.
      if (_autoplay && currentSong != null) {
        await _infillSmartQueue(currentSong!);
        for (int i = _currentIndex + 1; i < _queue.length; i++) {
          final s = _queue[i];
          final key = SongParserUtils.songDeduplicationKey(s);
          if (s.id != currentSong?.id && (curKey.isEmpty || key != curKey)) {
            foundIndex = i;
            break;
          }
        }
        if (foundIndex != -1) {
          await skipToQueueIndex(foundIndex);
          return;
        }
      }

      // If user tapped Next (!fromCompletion && _queue.length > 1) or loopMode == LoopMode.all,
      // scan from beginning of queue up to current to wrap around seamlessly
      if (_loopMode == LoopMode.all || (!fromCompletion && _queue.length > 1)) {
        for (int i = 0; i < _currentIndex; i++) {
          final s = _queue[i];
          final key = SongParserUtils.songDeduplicationKey(s);
          if (s.id != currentSong?.id && (curKey.isEmpty || key != curKey)) {
            foundIndex = i;
            break;
          }
        }
        if (foundIndex != -1) {
          await skipToQueueIndex(foundIndex);
          return;
        }
      }

      // Still no distinct track in queue: find fallback track or search live online
      Song? fallback = _findDistinctNextTrack();

      // Proactively fetch live online tracks for currentSong if in-memory pool was exhausted
      if (fallback == null && currentSong != null) {
        try {
          final seedLang = MusicApiService.detectSongLanguage(currentSong!);
          final seedEra = MusicTagClassifier.detectSongEra(currentSong!);
          final targetedQueries = AiRecommendationEngine.getEraTargetedQueries(
            seedLang,
            seedEra,
            currentSong!,
          );
          for (final query in targetedQueries) {
            final liveResults = await MusicApiService.searchLiveSongs(
              query,
              limit: 15,
            );
            final candidates = liveResults
                .where(
                  (s) =>
                      s.id != currentSong!.id &&
                      (curKey.isEmpty ||
                          SongParserUtils.songDeduplicationKey(s) != curKey) &&
                      s.audioUrl.isNotEmpty &&
                      MusicApiService.detectSongLanguage(s) == seedLang &&
                      (seedLang == 'English'
                          ? MusicTagClassifier.isEnglishSong(s)
                          : !MusicTagClassifier.isEnglishSong(s)),
                )
                .toList();
            if (candidates.isNotEmpty) {
              final eraMatches = candidates
                  .where((s) => MusicTagClassifier.detectSongEra(s) == seedEra)
                  .toList();
              if (eraMatches.isNotEmpty) {
                fallback = eraMatches.first;
                _allSongs.addAll(eraMatches);
                _appendTracksToQueueAndPlaylistSource(eraMatches);
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('[next] Live fallback search error: $e');
        }
      }

      // Safety net: find a distinct song from existing queue, library, or history matching seed era & language
      if (fallback == null) {
        for (final s in _queue) {
          final key = SongParserUtils.songDeduplicationKey(s);
          if (s.id != currentSong?.id && (curKey.isEmpty || key != curKey)) {
            fallback = s;
            break;
          }
        }
      }
      if (fallback == null && currentSong != null) {
        final seedEra = MusicTagClassifier.detectSongEra(currentSong!);
        final seedLang = MusicApiService.detectSongLanguage(currentSong!);
        for (final s in _allSongs) {
          final key = SongParserUtils.songDeduplicationKey(s);
          if (s.id != currentSong?.id &&
              (curKey.isEmpty || key != curKey) &&
              MusicTagClassifier.detectSongEra(s) == seedEra &&
              MusicApiService.detectSongLanguage(s) == seedLang &&
              (seedLang == 'English'
                  ? MusicTagClassifier.isEnglishSong(s)
                  : !MusicTagClassifier.isEnglishSong(s))) {
            fallback = s;
            break;
          }
        }
      }
      if (fallback == null && currentSong != null) {
        final seedEra = MusicTagClassifier.detectSongEra(currentSong!);
        final seedLang = MusicApiService.detectSongLanguage(currentSong!);
        for (final s in DatabaseService.instance.historySongs) {
          final key = SongParserUtils.songDeduplicationKey(s);
          if (s.id != currentSong?.id &&
              (curKey.isEmpty || key != curKey) &&
              MusicTagClassifier.detectSongEra(s) == seedEra &&
              MusicApiService.detectSongLanguage(s) == seedLang &&
              (seedLang == 'English'
                  ? MusicTagClassifier.isEnglishSong(s)
                  : !MusicTagClassifier.isEnglishSong(s))) {
            fallback = s;
            break;
          }
        }
      }

      final fallbackKey = fallback != null
          ? SongParserUtils.songDeduplicationKey(fallback)
          : '';

      if (fallback != null &&
          fallback.id != currentSong?.id &&
          (curKey.isEmpty || fallbackKey.isEmpty || fallbackKey != curKey)) {
        if (!_queue.any(
          (s) =>
              s.id == fallback!.id ||
              SongParserUtils.songDeduplicationKey(s) == fallbackKey,
        )) {
          _queue.add(fallback);
        }
        _queue = SongParserUtils.deduplicateSongs(_queue);
        await playSong(fallback, newQueue: List.from(_queue));
        return;
      } else {
        // Absolutely no other song could be found - do not replay the same song in a loop
        await pause();
        return;
      }
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> previous() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      if (_queue.isEmpty && DatabaseService.instance.historySongs.isEmpty) {
        return;
      }

      final curKey = currentSong != null
          ? SongParserUtils.songDeduplicationKey(currentSong!)
          : '';

      // 1. If we have previous tracks in the current queue:
      if (_currentIndex > 0) {
        int prevIndex = -1;
        for (int i = _currentIndex - 1; i >= 0; i--) {
          final s = _queue[i];
          final key = SongParserUtils.songDeduplicationKey(s);
          if (s.id != currentSong?.id && (curKey.isEmpty || key != curKey)) {
            prevIndex = i;
            break;
          }
        }
        if (prevIndex != -1) {
          await skipToQueueIndex(prevIndex);
          return;
        }
      }

      // 2. If at beginning of queue (_currentIndex <= 0) or single-song queue:
      // Check listening history so the user can navigate back to earlier played songs!
      final history = DatabaseService.instance.historySongs;
      Song? prevHistorySong;
      for (final s in history) {
        if (s.id == currentSong?.id) continue;
        if (curKey.isNotEmpty &&
            SongParserUtils.songDeduplicationKey(s) == curKey) {
          continue;
        }
        prevHistorySong = s;
        break;
      }

      if (prevHistorySong != null) {
        final prevKey = SongParserUtils.songDeduplicationKey(prevHistorySong);
        if (!_queue.any(
          (s) =>
              s.id == prevHistorySong!.id ||
              SongParserUtils.songDeduplicationKey(s) == prevKey,
        )) {
          _queue.insert(0, prevHistorySong);
        }
        _queue = SongParserUtils.deduplicateSongs(_queue);
        _currentIndex = _queue.indexWhere((s) => s.id == prevHistorySong!.id);
        if (_currentIndex == -1) {
          _currentIndex = _queue.indexWhere(
            (s) => SongParserUtils.songDeduplicationKey(s) == prevKey,
          );
        }
        if (_currentIndex == -1) _currentIndex = 0;
        await playSong(prevHistorySong, newQueue: List.from(_queue));
        return;
      }

      // 3. If queue has multiple tracks, wrap to last distinct track
      if (_queue.length > 1) {
        for (int i = _queue.length - 1; i > _currentIndex; i--) {
          final s = _queue[i];
          final key = SongParserUtils.songDeduplicationKey(s);
          if (s.id != currentSong?.id && (curKey.isEmpty || key != curKey)) {
            await skipToQueueIndex(i);
            return;
          }
        }
      }

      // 4. Fallback to allSongs
      for (final s in _allSongs) {
        final key = SongParserUtils.songDeduplicationKey(s);
        if (s.id != currentSong?.id && (curKey.isEmpty || key != curKey)) {
          if (!_queue.any(
            (q) =>
                q.id == s.id || SongParserUtils.songDeduplicationKey(q) == key,
          )) {
            _queue.insert(0, s);
          }
          _queue = SongParserUtils.deduplicateSongs(_queue);
          await playSong(s, newQueue: List.from(_queue));
          return;
        }
      }

      // 5. Truly no other song anywhere: restart track from 0:00
      await seek(Duration.zero);
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> seek(Duration newPosition) async {
    _position = newPosition;
    final dur = _duration.inSeconds > 0
        ? _duration.inSeconds.toDouble()
        : (currentSong != null
              ? currentSong!.duration.inSeconds.toDouble()
              : 240.0);
    MediaSessionService.updatePositionState(
      durationSeconds: dur,
      positionSeconds: newPosition.inSeconds.toDouble(),
      playbackRate: _playbackSpeed,
    );
    notifyListeners();
    try {
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      debugPrint('[Playback] seek error ignored: $e');
    }
  }

  void _handleSongCompletion() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      if (_sleepAfterCurrentSong) {
        cancelSleepTimer();
        await _audioPlayer.pause();
        _isPlaying = false;
        notifyListeners();
        return;
      }

      if (_loopMode == LoopMode.one) {
        await _audioPlayer.seek(Duration.zero);
        _startPlayback();
        return;
      }

      if (_currentIndex < _queue.length - 1) {
        await next(fromCompletion: true);
      } else if (_autoplay && currentSong != null) {
        await _infillSmartQueue(currentSong!);
        await next(fromCompletion: true);
      } else if (_loopMode == LoopMode.all && _queue.isNotEmpty) {
        if (_queue.length > 1) {
          await playSong(_queue[0]);
        } else {
          await next(fromCompletion: true);
        }
      } else {
        _isPlaying = false;
        MediaSessionService.updatePlaybackState(isPlaying: false);
        notifyListeners();
      }
    } catch (_) {
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  Future<void> toggleLoopMode() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    await _audioPlayer.setLoopMode(
      _loopMode == LoopMode.one ? LoopMode.one : LoopMode.off,
    );
    notifyListeners();
  }

  Future<void> cycleRepeatAndAutoplayMode() async {
    if (_loopMode == LoopMode.off && _autoplay) {
      // 1. Switch from Autoplay to Repeat Queue
      _autoplay = false;
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      // 2. Switch from Repeat Queue to Repeat Current Track
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      // 3. Switch to Repeat Off
      _loopMode = LoopMode.off;
      _autoplay = false;
    } else {
      // 4. Switch back to Autoplay (Infinite Radio)
      _loopMode = LoopMode.off;
      _autoplay = true;
      if (currentSong != null && _queue.length < 30) {
        _infillSmartQueue(currentSong!);
      }
    }
    await _audioPlayer.setLoopMode(
      _loopMode == LoopMode.one ? LoopMode.one : LoopMode.off,
    );
    DatabaseService.instance.updateSetting('autoplay', _autoplay);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setSpeed(speed);
    final dur = _duration.inSeconds > 0
        ? _duration.inSeconds.toDouble()
        : (currentSong != null
              ? currentSong!.duration.inSeconds.toDouble()
              : 240.0);
    MediaSessionService.updatePositionState(
      durationSeconds: dur,
      positionSeconds: _position.inSeconds.toDouble(),
      playbackRate: _playbackSpeed,
    );
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    try {
      _isPlaying = false;
      _isBuffering = false;
      _position = Duration.zero;
      _currentIndex = -1;
      _queue.clear();
      _currentSong = null;
      unawaited(BatteryOptimizationService.releaseWakeLock());
      await _audioPlayer.stop();
      MediaSessionService.updatePlaybackState(isPlaying: false);
      PresenceService.instance.updateListeningStatus(
        song: null,
        isPlaying: false,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('stopPlayback note: $e');
    }
  }

  void _onDatabaseChanged() {
    _hydrateFromDatabase();
    notifyListeners();
  }

  void _onDownloadsChanged() {
    final downloaded = DownloadService().downloadedSongs;
    if (downloaded.isNotEmpty) {
      final Set<String> ids = _allSongs.map((s) => s.id).toSet();
      for (final dl in downloaded) {
        if (!ids.contains(dl.id)) {
          _allSongs.insert(0, dl);
        }
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    DatabaseService.instance.removeListener(_onDatabaseChanged);
    DownloadService().removeListener(_onDownloadsChanged);
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
