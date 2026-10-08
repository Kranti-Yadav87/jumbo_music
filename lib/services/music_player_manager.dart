import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../data/music_repository.dart';
import 'music_api_service.dart';
import 'privacy_security_service.dart';
import 'database_service.dart';
import 'download_service.dart';
import 'eq_presets.dart';
import 'presence_service.dart';
import 'media_session_service.dart';
import 'crash_reporting_service.dart';

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
    if (currentSong != null) {
      _queue = queue ?? [currentSong];
      _currentIndex = 0;
    } else if (queue != null) {
      _queue = queue;
      _currentIndex = queue.isNotEmpty ? 0 : -1;
    } else {
      _queue = [];
      _currentIndex = -1;
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
    _queue = [];
    _currentIndex = -1;
    _isPlaying = false;
    _isBuffering = false;
    _favoriteIds.clear();
    notifyListeners();
  }

  static bool get _isAndroidNative =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Real hardware equalizer. just_audio only supports it on Android.
  final AndroidEqualizer? _equalizer = _isAndroidNative
      ? AndroidEqualizer()
      : null;
  bool get equalizerSupported => _equalizer != null;

  late final AudioPlayer _audioPlayer = _buildPlayer();

  AudioPlayer _buildPlayer() {
    final eq = _equalizer;
    return AudioPlayer(
      audioPipeline: eq == null
          ? null
          : AudioPipeline(androidAudioEffects: [eq]),
    );
  }

  List<Song> _allSongs = [];
  List<Song> _queue = [];
  int _currentIndex = -1;

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

  MusicPlayerManager._internal() {
    _init();
  }

  // Getters
  List<Song> get allSongs => _allSongs;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _queue.length)
      ? _queue[_currentIndex]
      : null;

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

    _playlists = List.from(MusicRepository.samplePlaylists);
    _queue = List.from(_allSongs);

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
    _soundPreset = db.getSetting('soundPreset', 'Normal') as String;
    _volume = (db.getSetting('volume', 1.0) as num).toDouble();
    _playbackSpeed = (db.getSetting('playbackSpeed', 1.0) as num).toDouble();

    _favoriteIds.clear();
    _favoriteIds.addAll(db.favoriteIds);

    _playlists.removeWhere(
      (p) =>
          p.type == PlaylistType.custom || p.type == PlaylistType.sharedBlend,
    );
    for (final p in db.customPlaylists) {
      if (!_playlists.any((item) => item.id == p.id)) {
        _playlists.insert(0, p);
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
      if (_queue.isEmpty) {
        _queue = List.from(_allSongs);
      }
    }
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

        if (livePlaylists.isNotEmpty) {
          _playlists = [...livePlaylists, ..._playlists];
        }

        _queue = List.from(_allSongs);
      }
    } catch (error) {
      CrashReportingService.swallow(error, 'music_player_manager.dart:441');
    }

    _isLoadingTrending = false;
    notifyListeners();
  }

  /// Plays a song selected from Search and automatically builds a focused,
  /// 50-60 song smart queue tailored strictly to that song's era, artist, and genre.
  Future<void> playSongFromSearch(Song song) async {
    await playSong(song, newQueue: [song]);
    _infillSmartQueue(song, targetQueueSize: 60);
  }

  Future<void> playSong(
    Song song, {
    List<Song>? newQueue,
    List<Song>? playlistContext,
  }) async {
    _isTransitioning = true;
    _errorMessage = null;

    if (!_allSongs.any((s) => s.id == song.id)) {
      _allSongs.insert(0, song);
    }

    final queueToUse = newQueue ?? playlistContext;
    if (queueToUse != null && queueToUse.isNotEmpty) {
      _queue = List.from(queueToUse);
    } else if (_queue.isEmpty || !_queue.any((s) => s.id == song.id)) {
      _queue = [song];
    }

    final songLang = MusicApiService.detectSongLanguage(song);
    final isVintage =
        songLang == 'Hindi' && MusicApiService.isVintageGoldenEra(song);
    final is90s =
        songLang == 'Hindi' &&
        !isVintage &&
        MusicApiService.is90sMelodyEra(song);
    final is2000s =
        songLang == 'Hindi' &&
        !isVintage &&
        !is90s &&
        MusicApiService.is2000sSong(song);
    final isIndie =
        songLang == 'Hindi' &&
        !isVintage &&
        !is90s &&
        !is2000s &&
        MusicApiService.isIndieOrSukoonSong(song);

    if (_autoplay && _queue.length < 50 && _allSongs.isNotEmpty) {
      final Set<String> currentQueueIds = _queue.map((s) => s.id).toSet();
      final localCandidates = _allSongs.where((s) {
        if (currentQueueIds.contains(s.id)) return false;
        if (s.duration.inSeconds > 0 && s.duration.inSeconds < 60) return false;
        final candLang = MusicApiService.detectSongLanguage(s);
        if (candLang != songLang) return false;

        if (songLang == 'Hindi') {
          if (isVintage) return MusicApiService.isVintageGoldenEra(s);
          if (is90s) return MusicApiService.is90sMelodyEra(s);
          if (is2000s) return MusicApiService.is2000sSong(s);
          if (isIndie) return MusicApiService.isIndieOrSukoonSong(s);
          return !MusicApiService.isVintageGoldenEra(s) &&
              !MusicApiService.is90sMelodyEra(s);
        }
        return true;
      }).toList();

      localCandidates.sort((a, b) {
        int scoreA =
            (a.artist == song.artist ? 3 : 0) + (a.genre == song.genre ? 1 : 0);
        int scoreB =
            (b.artist == song.artist ? 3 : 0) + (b.genre == song.genre ? 1 : 0);
        return scoreB.compareTo(scoreA);
      });
      _queue.addAll(localCandidates.take(60 - _queue.length));
    }

    if (_queue.length > 60) {
      final currentIdxInQueue = _queue.indexWhere((s) => s.id == song.id);
      if (currentIdxInQueue != -1) {
        final start = (currentIdxInQueue - 5).clamp(0, _queue.length);
        final end = (start + 60).clamp(0, _queue.length);
        _queue = _queue.sublist(start, end);
      } else {
        _queue = _queue.take(60).toList();
      }
    }

    final index = _queue.indexWhere((s) => s.id == song.id);
    _currentIndex = index != -1 ? index : 0;

    _recentlyPlayed.removeWhere((item) => item.id == song.id);
    _recentlyPlayed.insert(0, song);
    DatabaseService.instance.addHistory(song);

    _updateDynamicLibrary(song);
    if (_autoplay) {
      _infillSmartQueue(song, targetQueueSize: 60);
    }

    _isPlaying = true;
    _isBuffering = true;
    _position = Duration.zero;
    _duration = song.duration;
    notifyListeners();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      Permission.notification.isGranted.then((granted) {
        if (!granted) {
          Permission.notification.request();
        }
      });
    }

    try {
      MediaSessionService.updateMetadata(
        title: song.title,
        artist: song.artist,
        album: song.album.isNotEmpty ? song.album : 'Jumbo Music',
        coverUrl: song.coverUrl,
      );
      MediaSessionService.updatePlaybackState(isPlaying: true);
      MediaSessionService.updatePositionState(
        durationSeconds: song.duration.inSeconds > 0
            ? song.duration.inSeconds.toDouble()
            : 240.0,
        positionSeconds: 0.0,
        playbackRate: _playbackSpeed,
      );

      final mediaItem = MediaItem(
        id: song.id,
        album: song.album.isNotEmpty ? song.album : 'Jumbo Music',
        title: song.title,
        artist: song.artist,
        artUri: song.coverUrl.isNotEmpty ? Uri.tryParse(song.coverUrl) : null,
        duration: song.duration.inSeconds > 0 ? song.duration : null,
        playable: true,
        displayTitle: song.title,
        displaySubtitle: song.artist,
        displayDescription: song.album.isNotEmpty ? song.album : 'Jumbo Music',
      );

      final isDl = DownloadService().isDownloaded(song.id);
      final offlineUri = await DownloadService().playableUriFor(
        song.id,
        title: song.title,
      );
      debugPrint(
        '[Playback] START: "${song.title}" (${song.id}) - isDownloaded: $isDl, offlineUri: $offlineUri',
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
            '[Playback] NOTICE: "${song.title}" is in downloaded list but local file not found. Falling back to stream URI.',
          );
        }
        sourceUri = Uri.parse(song.audioUrl);
        debugPrint('[Playback] CHOSEN SOURCE URI: $sourceUri (network stream)');
      }

      await _audioPlayer.setAudioSource(
        AudioSource.uri(sourceUri, tag: mediaItem),
        preload: true,
      );
      unawaited(_applyEqualizerPreset());
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setLoopMode(
        _loopMode == LoopMode.one ? LoopMode.one : LoopMode.off,
      );
      _startPlayback();
      _isPlaying = true;
      _isBuffering = false;
    } catch (e) {
      // 10/10 Resilience: Attempt automatic stream auto-heal if online URL was expired or broken
      final isDl = DownloadService().isDownloaded(song.id);
      if (!isDl && song.title.isNotEmpty) {
        try {
          debugPrint(
            '[Playback] Attempting stream auto-heal for "${song.title}"...',
          );
          final healedSongs = await MusicApiService.searchLiveSongs(
            '${song.title} ${song.artist}',
            limit: 3,
          );
          if (healedSongs.isNotEmpty &&
              healedSongs.first.audioUrl.isNotEmpty &&
              healedSongs.first.audioUrl != song.audioUrl) {
            final freshTrack = song.copyWith(
              audioUrl: healedSongs.first.audioUrl,
            );
            final idx = _queue.indexWhere((s) => s.id == song.id);
            if (idx != -1) _queue[idx] = freshTrack;

            final mediaItem = MediaItem(
              id: freshTrack.id,
              album: freshTrack.album.isNotEmpty
                  ? freshTrack.album
                  : 'Jumbo Music',
              title: freshTrack.title,
              artist: freshTrack.artist,
              artUri: freshTrack.coverUrl.isNotEmpty
                  ? Uri.tryParse(freshTrack.coverUrl)
                  : null,
              duration: freshTrack.duration.inSeconds > 0
                  ? freshTrack.duration
                  : null,
              playable: true,
              displayTitle: freshTrack.title,
              displaySubtitle: freshTrack.artist,
              displayDescription: freshTrack.album.isNotEmpty
                  ? freshTrack.album
                  : 'Jumbo Music',
            );

            await _audioPlayer.setAudioSource(
              AudioSource.uri(Uri.parse(freshTrack.audioUrl), tag: mediaItem),
              preload: true,
            );
            unawaited(_applyEqualizerPreset());
            await _audioPlayer.seek(Duration.zero);
            await _audioPlayer.setSpeed(_playbackSpeed);
            await _audioPlayer.setVolume(_volume);
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
          await DownloadService().playableUriFor(song.id, title: song.title) ==
              null) {
        _errorMessage =
            "Offline audio file for '${song.title}' was not found in local storage. Connect to internet to stream.";
      } else {
        _errorMessage = "Unable to play audio: $e";
      }
      debugPrint('[Playback] FAILED: $_errorMessage (original: $e)');
      _isBuffering = false;
      _isPlaying = false;
      MediaSessionService.updatePlaybackState(isPlaying: false);
    } finally {
      _isTransitioning = false;
      notifyListeners();
    }
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    _queue = List.from(songs);
    final targetIndex = (initialIndex >= 0 && initialIndex < songs.length)
        ? initialIndex
        : 0;
    await playSong(_queue[targetIndex]);
  }

  void _startPlayback() {
    unawaited(
      _audioPlayer.play().catchError((Object e) {
        _errorMessage = 'Playback error: $e';
        _isPlaying = false;
        _isBuffering = false;
        notifyListeners();
      }),
    );
  }

  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
    MediaSessionService.updatePlaybackState(isPlaying: false);
    await _audioPlayer.pause();
  }

  Future<void> play() async {
    if (currentSong == null && _allSongs.isNotEmpty) {
      await playSong(_allSongs[0]);
      return;
    }
    _isPlaying = true;
    notifyListeners();
    MediaSessionService.updatePlaybackState(isPlaying: true);
    await _audioPlayer.play();
  }

  Future<void> togglePlay() async {
    if (currentSong == null && _allSongs.isNotEmpty) {
      await playSong(_allSongs[0]);
      return;
    }

    try {
      if (_isPlaying || _audioPlayer.playing) {
        _isPlaying = false;
        notifyListeners();
        MediaSessionService.updatePlaybackState(isPlaying: false);
        await _audioPlayer.pause();
      } else {
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
    final curTitle = currentSong?.title.trim().toLowerCase();

    // 1. Check allSongs
    final candidatePool = _allSongs.where((s) {
      if (s.id == curId) return false;
      if (curTitle != null && s.title.trim().toLowerCase() == curTitle) {
        return false;
      }
      return s.audioUrl.isNotEmpty;
    }).toList();

    if (candidatePool.isNotEmpty) {
      final recentIds = _recentlyPlayed.take(10).map((s) => s.id).toSet();
      final fresh = candidatePool
          .where((s) => !recentIds.contains(s.id))
          .toList();
      final list = fresh.isNotEmpty ? fresh : candidatePool;
      list.shuffle();
      return list.first;
    }

    // 2. Check offline downloads
    final dlSongs = DownloadService().downloadedSongs.where((s) {
      if (s.id == curId) return false;
      if (curTitle != null && s.title.trim().toLowerCase() == curTitle) {
        return false;
      }
      return true;
    }).toList();
    if (dlSongs.isNotEmpty) {
      dlSongs.shuffle();
      return dlSongs.first;
    }

    return null;
  }

  Future<void> next() async {
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

    if (_isShuffle && _queue.length > 1) {
      final List<int> candidates = [];
      for (int i = 0; i < _queue.length; i++) {
        if (i != _currentIndex && _queue[i].id != currentSong?.id) {
          candidates.add(i);
        }
      }
      if (candidates.isNotEmpty) {
        candidates.shuffle();
        await playSong(_queue[candidates.first]);
        return;
      }
    }

    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _queue.length) {
      if (_autoplay && currentSong != null) {
        await _infillSmartQueue(currentSong!);
        if (_queue.length > nextIndex) {
          await playSong(_queue[nextIndex]);
          return;
        }
      }
      nextIndex = 0;
    }

    final target = _queue[nextIndex];
    // Next button must never re-play the exact same track when other tracks exist
    if (target.id == currentSong?.id && _loopMode != LoopMode.one) {
      final fallback = _findDistinctNextTrack();
      if (fallback != null) {
        _queue.add(fallback);
        await playSong(fallback);
        return;
      }
    }

    await playSong(target);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = _queue.length - 1;
    }

    await playSong(_queue[prevIndex]);
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
    await _audioPlayer.seek(newPosition);
  }

  void _handleSongCompletion() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      if (_sleepAfterCurrentSong) {
        cancelSleepTimer();
        await _audioPlayer.pause();
        _isPlaying = false;
        _isTransitioning = false;
        notifyListeners();
        return;
      }

      if (_loopMode == LoopMode.one) {
        await _audioPlayer.seek(Duration.zero);
        _startPlayback();
        _isTransitioning = false;
        return;
      }

      if (_currentIndex < _queue.length - 1) {
        _isTransitioning = false;
        await next();
      } else if (_autoplay && currentSong != null) {
        await _infillSmartQueue(currentSong!);
        _isTransitioning = false;
        await next();
      } else if (_loopMode == LoopMode.all && _queue.isNotEmpty) {
        _isTransitioning = false;
        if (_queue.length > 1) {
          await playSong(_queue[0]);
        } else {
          await next();
        }
      } else {
        _isPlaying = false;
        _isTransitioning = false;
        MediaSessionService.updatePlaybackState(isPlaying: false);
        notifyListeners();
      }
    } catch (_) {
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
    _audioPlayer.dispose();
    super.dispose();
  }
}
