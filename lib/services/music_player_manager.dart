import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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

class MusicPlayerManager extends ChangeNotifier {
  static final MusicPlayerManager _instance = MusicPlayerManager._internal();
  factory MusicPlayerManager() => _instance;

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
  List<Playlist> get smartMixes =>
      _playlists.where((p) => p.type == PlaylistType.smartMix).toList();
  List<Playlist> get userPlaylists =>
      _playlists.where((p) => p.type == PlaylistType.custom).toList();
  List<Song> get onlineTrending => _onlineTrending;
  List<Song> get top50Songs => _allSongs.take(50).toList();
  List<Song> get newReleases => _newReleases.isNotEmpty
      ? _newReleases
      : _onlineTrending.take(20).toList();
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
    db.addListener(() {
      _hydrateFromDatabase();
      notifyListeners();
    });

    // Register MediaSession lock screen action handlers
    MediaSessionService.registerActionHandler((action, param) {
      switch (action) {
        case 'play':
          if (!_isPlaying) togglePlay();
          break;
        case 'pause':
          if (_isPlaying) togglePlay();
          break;
        case 'next':
          next();
          break;
        case 'previous':
          previous();
          break;
        case 'seek':
          seek(Duration(seconds: param.toInt()));
          break;
        case 'seekforward':
          seek(
            _position +
                Duration(seconds: param.toInt() > 0 ? param.toInt() : 10),
          );
          break;
        case 'seekbackward':
          final target =
              _position.inSeconds - (param.toInt() > 0 ? param.toInt() : 10);
          seek(Duration(seconds: target > 0 ? target : 0));
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

      // Web Audio fallback: if song reaches the end, trigger completion seamlessly
      if (_duration > const Duration(seconds: 2) &&
          pos >= _duration - const Duration(milliseconds: 300) &&
          _isPlaying &&
          !_isTransitioning) {
        _handleSongCompletion();
      }
      notifyListeners();
    });

    // Listen to duration
    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        MediaSessionService.updatePositionState(
          durationSeconds: dur.inSeconds.toDouble(),
          positionSeconds: _position.inSeconds.toDouble(),
          playbackRate: _playbackSpeed,
        );
        notifyListeners();
      }
    });

    // Listen to buffer position
    _bufferedPositionSubscription = _audioPlayer.bufferedPositionStream.listen((
      buf,
    ) {
      _bufferedPosition = buf;
      notifyListeners();
    });

    // Asynchronously fetch online trending songs with fallback
    fetchOnlineTrending();
  }

  void _hydrateFromDatabase() {
    final db = DatabaseService.instance;

    _autoplay = db.getSetting('autoplay', true) as bool;
    _soundPreset = db.getSetting('soundPreset', 'Normal') as String;
    _volume = (db.getSetting('volume', 1.0) as num).toDouble();
    _playbackSpeed = (db.getSetting('playbackSpeed', 1.0) as num).toDouble();

    // Reset favorites
    _favoriteIds.clear();
    _favoriteIds.addAll(db.favoriteIds);

    // Rebuild custom playlists from db.customPlaylists
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

    // Ensure all downloaded songs are part of _allSongs on startup for offline playback
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

      // Fetch live fresh studio new releases (2024-2025 Bollywood / Indian pop)
      try {
        final newReleasesResult = await MusicApiService.searchLiveSongs(
          'Latest Bollywood Hindi New 2024 2025',
          limit: 30,
        );
        if (newReleasesResult.isNotEmpty) {
          _newReleases = newReleasesResult;
        }
      } catch (_) {}

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
    } catch (_) {}

    _isLoadingTrending = false;
    notifyListeners();
  }

  void _updateDynamicLibrary(Song song) {
    // 1. Recently Played (up to 40) - Skipped if Incognito Mode is active for privacy
    if (!PrivacySecurityService().isIncognitoMode) {
      _recentlyPlayed.removeWhere((s) => s.id == song.id);
      _recentlyPlayed.insert(0, song);
      if (_recentlyPlayed.length > 40) {
        _recentlyPlayed.removeLast();
      }
    }

    // 2. Artist Mix Station
    final rawArtist = song.artist.split(',').first.split('&').first.trim();
    final mainArtist = rawArtist.isNotEmpty ? rawArtist : 'Featured Artist';
    final artistPlaylistId =
        'artist_${mainArtist.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    final artistIndex = _playlists.indexWhere((p) => p.id == artistPlaylistId);
    if (artistIndex != -1) {
      final existing = _playlists[artistIndex];
      final updatedSongs = List<Song>.from(existing.songs);
      if (!updatedSongs.any((s) => s.id == song.id)) {
        updatedSongs.insert(0, song);
      }
      final updatedIds = List<String>.from(existing.songIds);
      if (!updatedIds.contains(song.id)) {
        updatedIds.insert(0, song.id);
      }
      _playlists[artistIndex] = existing.copyWith(
        songIds: updatedIds,
        songs: updatedSongs,
        coverUrl: song.coverUrl.isNotEmpty ? song.coverUrl : existing.coverUrl,
      );
    } else {
      _playlists.insert(
        0,
        Playlist(
          id: artistPlaylistId,
          title: '$mainArtist Radio',
          description: 'Non-stop top tracks by $mainArtist & related artists',
          coverUrl: song.coverUrl,
          songIds: [song.id],
          songs: [song],
          type: PlaylistType.artistMix,
        ),
      );
    }

    // 3. Mood / Genre Station
    final genre = song.genre.isNotEmpty ? song.genre : 'Bollywood';
    final genrePlaylistId =
        'genre_${genre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    final genreIndex = _playlists.indexWhere((p) => p.id == genrePlaylistId);
    if (genreIndex != -1) {
      final existing = _playlists[genreIndex];
      final updatedSongs = List<Song>.from(existing.songs);
      if (!updatedSongs.any((s) => s.id == song.id)) {
        updatedSongs.insert(0, song);
      }
      final updatedIds = List<String>.from(existing.songIds);
      if (!updatedIds.contains(song.id)) {
        updatedIds.insert(0, song.id);
      }
      _playlists[genreIndex] = existing.copyWith(
        songIds: updatedIds,
        songs: updatedSongs,
      );
    } else {
      _playlists.insert(
        0,
        Playlist(
          id: genrePlaylistId,
          title: '$genre Station',
          description: 'Endless $genre rhythms & live beats',
          coverUrl: song.coverUrl,
          songIds: [song.id],
          songs: [song],
          type: PlaylistType.genreMix,
        ),
      );
    }

    // 4. "Made For You" Daily Smart Mix
    const smartMixId = 'smart_mix_daily';
    final smartIndex = _playlists.indexWhere((p) => p.id == smartMixId);
    if (smartIndex != -1) {
      final existing = _playlists[smartIndex];
      final updatedSongs = List<Song>.from(existing.songs);
      if (!updatedSongs.any((s) => s.id == song.id)) {
        updatedSongs.insert(0, song);
        if (updatedSongs.length > 30) updatedSongs.removeLast();
      }
      _playlists[smartIndex] = existing.copyWith(
        songs: updatedSongs,
        songIds: updatedSongs.map((s) => s.id).toList(),
      );
    } else {
      _playlists.insert(
        0,
        Playlist(
          id: smartMixId,
          title: 'Daily Smart Mix',
          description: 'Personalized mix based on your listening journey',
          coverUrl: song.coverUrl,
          songIds: [song.id],
          songs: [song],
          type: PlaylistType.smartMix,
        ),
      );
    }
  }

  Future<void> _infillSmartQueue(
    Song seedSong, {
    int targetQueueSize = 60,
  }) async {
    if (!_autoplay || _isLoadingRecommendations || _isQueueLocked) return;
    if (_lastInfilledSongId == seedSong.id &&
        _queue.length >= targetQueueSize) {
      return;
    }
    _lastInfilledSongId = seedSong.id;

    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      final songLang = MusicApiService.detectSongLanguage(seedSong);
      final is70s =
          songLang == 'Hindi' && MusicApiService.isVintageGoldenEra(seedSong);
      final is80s =
          songLang == 'Hindi' && !is70s && MusicApiService.is80sEra(seedSong);
      final is90s =
          songLang == 'Hindi' &&
          !is70s &&
          !is80s &&
          MusicApiService.is90sMelodyEra(seedSong);
      final is2000s =
          songLang == 'Hindi' &&
          !is70s &&
          !is80s &&
          !is90s &&
          MusicApiService.is2000sSong(seedSong);
      final is2010s =
          songLang == 'Hindi' &&
          !is70s &&
          !is80s &&
          !is90s &&
          !is2000s &&
          MusicApiService.is2010sSong(seedSong);
      final isIndie =
          songLang == 'Hindi' &&
          !is70s &&
          !is80s &&
          !is90s &&
          !is2000s &&
          !is2010s &&
          MusicApiService.isIndieOrSukoonSong(seedSong);

      // 1. First immediately seed from local _allSongs strictly matching language & era
      if (_queue.length < targetQueueSize && _allSongs.isNotEmpty) {
        final Set<String> currentQueueIds = _queue.map((s) => s.id).toSet();
        final localCandidates = _allSongs.where((s) {
          if (currentQueueIds.contains(s.id)) return false;
          final candLang = MusicApiService.detectSongLanguage(s);
          if (candLang != songLang) return false;

          if (songLang == 'Hindi') {
            if (is70s) {
              return MusicApiService.isVintageGoldenEra(s) &&
                  !MusicApiService.is80sEra(s) &&
                  !MusicApiService.is90sMelodyEra(s);
            }
            if (is80s) {
              return MusicApiService.is80sEra(s) &&
                  !MusicApiService.isVintageGoldenEra(s) &&
                  !MusicApiService.is90sMelodyEra(s);
            }
            if (is90s) {
              return MusicApiService.is90sMelodyEra(s) &&
                  !MusicApiService.isVintageGoldenEra(s) &&
                  !MusicApiService.is80sEra(s);
            }
            if (is2000s) {
              return MusicApiService.is2000sSong(s) &&
                  !MusicApiService.is90sMelodyEra(s);
            }
            if (is2010s) return MusicApiService.is2010sSong(s);
            if (isIndie) return MusicApiService.isIndieOrSukoonSong(s);
            return !MusicApiService.isVintageGoldenEra(s) &&
                !MusicApiService.is80sEra(s) &&
                !MusicApiService.is90sMelodyEra(s);
          }
          return true;
        }).toList();

        localCandidates.sort((a, b) {
          int scoreA =
              (a.artist == seedSong.artist ? 3 : 0) +
              (a.genre == seedSong.genre ? 1 : 0);
          int scoreB =
              (b.artist == seedSong.artist ? 3 : 0) +
              (b.genre == seedSong.genre ? 1 : 0);
          return scoreB.compareTo(scoreA);
        });

        final needed = targetQueueSize - _queue.length;
        if (needed > 0 && localCandidates.isNotEmpty) {
          _queue.addAll(localCandidates.take(needed));
          notifyListeners();
        }
      }

      // 2. Fetch fresh smart recommendations concurrently matching exact era and language
      final freshTracks = await MusicApiService.fetchSmartRecommendations(
        seedSong,
        limit: 55,
      );
      if (freshTracks.isNotEmpty) {
        final Set<String> playedIds = _queue
            .take(_currentIndex + 1)
            .map((s) => s.id)
            .toSet();
        final List<Song> newTracks = freshTracks
            .where((s) => !playedIds.contains(s.id))
            .toList();

        if (newTracks.isNotEmpty) {
          final playedPart = _queue.sublist(0, _currentIndex + 1);
          final upcomingPart = _queue.sublist(_currentIndex + 1);

          final Set<String> freshIds = newTracks.map((s) => s.id).toSet();
          final remainingUpcoming = upcomingPart.where((s) {
            if (freshIds.contains(s.id)) return false;
            final candLang = MusicApiService.detectSongLanguage(s);
            if (candLang != songLang) return false;
            if (songLang == 'Hindi') {
              if (is70s) {
                return MusicApiService.isVintageGoldenEra(s) &&
                    !MusicApiService.is80sEra(s) &&
                    !MusicApiService.is90sMelodyEra(s);
              }
              if (is80s) {
                return MusicApiService.is80sEra(s) &&
                    !MusicApiService.isVintageGoldenEra(s) &&
                    !MusicApiService.is90sMelodyEra(s);
              }
              if (is90s) {
                return MusicApiService.is90sMelodyEra(s) &&
                    !MusicApiService.isVintageGoldenEra(s) &&
                    !MusicApiService.is80sEra(s);
              }
              if (is2000s) {
                return MusicApiService.is2000sSong(s) &&
                    !MusicApiService.is90sMelodyEra(s);
              }
              if (is2010s) return MusicApiService.is2010sSong(s);
              if (isIndie) return MusicApiService.isIndieOrSukoonSong(s);
              return !MusicApiService.isVintageGoldenEra(s) &&
                  !MusicApiService.is80sEra(s) &&
                  !MusicApiService.is90sMelodyEra(s);
            }
            return true;
          }).toList();

          _queue = [
            ...playedPart,
            ...newTracks,
            ...remainingUpcoming,
          ].take(targetQueueSize).toList();

          // Add to allSongs as well
          final Set<String> allIds = _allSongs.map((s) => s.id).toSet();
          for (final track in newTracks) {
            if (!allIds.contains(track.id)) {
              _allSongs.add(track);
            }
          }
        }
      }
    } catch (_) {}

    _isLoadingRecommendations = false;
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

    // Ensure song is in _allSongs
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

    // Immediately ensure queue is populated with era & language matched songs if autoplay is active
    if (_autoplay && _queue.length < 50 && _allSongs.isNotEmpty) {
      final Set<String> currentQueueIds = _queue.map((s) => s.id).toSet();
      final localCandidates = _allSongs.where((s) {
        if (currentQueueIds.contains(s.id)) return false;
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

    // Keep queue focused around 50-60 songs max
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

    // Record to history and persist via DatabaseService
    _recentlyPlayed.removeWhere((item) => item.id == song.id);
    _recentlyPlayed.insert(0, song);
    DatabaseService.instance.addHistory(song);

    // Dynamic library generation & Smart queue infill
    _updateDynamicLibrary(song);
    if (_autoplay) {
      _infillSmartQueue(song, targetQueueSize: 60);
    }

    _isPlaying = true;
    _isBuffering = true;
    _position = Duration.zero;
    _duration = song.duration;
    notifyListeners();

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

      // 1. Set new audio source with preload & native lock screen metadata
      final mediaItem = MediaItem(
        id: song.id,
        album: song.album.isNotEmpty ? song.album : 'Jumbo Music',
        title: song.title,
        artist: song.artist,
        artUri: song.coverUrl.isNotEmpty ? Uri.tryParse(song.coverUrl) : null,
        duration: song.duration.inSeconds > 0 ? song.duration : null,
      );

      // Prefer the real offline file when this song was downloaded.
      final localPath = await DownloadService().playablePathFor(song.id);
      final sourceUri = localPath != null
          ? Uri.file(localPath)
          : Uri.parse(song.audioUrl);

      await _audioPlayer.setAudioSource(
        AudioSource.uri(sourceUri, tag: mediaItem),
        preload: true,
      );
      unawaited(_applyEqualizerPreset());
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setLoopMode(_loopMode);
      await _audioPlayer.play();
      _isPlaying = true;
      _isBuffering = false;
    } catch (e) {
      _errorMessage = "Unable to play audio: $e";
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
        await _audioPlayer.play();
      }
    } catch (e) {
      _errorMessage = "Playback toggle error: $e";
      _isPlaying = _audioPlayer.playing;
      notifyListeners();
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    // Proactively infill when within 6 songs of queue end
    if (_autoplay &&
        currentSong != null &&
        _currentIndex >= _queue.length - 6) {
      _infillSmartQueue(currentSong!);
    }

    if (_isShuffle && _queue.length > 1) {
      final List<int> candidates = [];
      for (int i = 0; i < _queue.length; i++) {
        if (i != _currentIndex) candidates.add(i);
      }
      candidates.shuffle();
      await playSong(_queue[candidates.first]);
      return;
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

    await playSong(_queue[nextIndex]);
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
        await _audioPlayer.play();
        _isTransitioning = false;
        return;
      }

      if (_loopMode == LoopMode.all) {
        _isTransitioning = false;
        await next();
        return;
      }

      // Normal or Autoplay flow
      if (_currentIndex < _queue.length - 1) {
        _isTransitioning = false;
        await next();
      } else if (_autoplay && currentSong != null) {
        // Proactively fetch fresh songs and continue uninterrupted playback
        await _infillSmartQueue(currentSong!);
        _isTransitioning = false;
        if (_currentIndex < _queue.length - 1) {
          await next();
        } else {
          // If queue ended, loop back from start
          await playSong(_queue[0]);
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
    await _audioPlayer.setLoopMode(_loopMode);
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

  // Volume & Mute Controls
  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    _isMuted = _volume == 0.0;
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      _volume = _preMuteVolume > 0.0 ? _preMuteVolume : 0.8;
      _isMuted = false;
    } else {
      _preMuteVolume = _volume;
      _volume = 0.0;
      _isMuted = true;
    }
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  // Sound Preset Control
  void setSoundPreset(String preset) {
    if (soundPresets.contains(preset)) {
      _soundPreset = preset;
      unawaited(_applyEqualizerPreset());
      notifyListeners();
    }
  }

  /// Applies the selected preset to the Android hardware equalizer.
  Future<void> _applyEqualizerPreset() async {
    final eq = _equalizer;
    if (eq == null) return;
    try {
      final params = await eq.parameters;
      final gains = EqPresets.gainsFor(
        _soundPreset,
        bandCount: params.bands.length,
        minDb: params.minDecibels,
        maxDb: params.maxDecibels,
      );
      for (var i = 0; i < params.bands.length; i++) {
        await params.bands[i].setGain(gains[i]);
      }
      await eq.setEnabled(_soundPreset != 'Normal');
    } catch (e) {
      debugPrint('Equalizer note: $e');
    }
  }

  // Sleep Timer Engine
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepSecondsRemaining = duration.inSeconds;
    _sleepAfterCurrentSong = false;
    notifyListeners();

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepSecondsRemaining > 0) {
        _sleepSecondsRemaining--;
        notifyListeners();
      } else {
        cancelSleepTimer();
        _audioPlayer.pause();
      }
    });
  }

  void setSleepTimerAfterSong() {
    cancelSleepTimer();
    _sleepAfterCurrentSong = true;
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimer = null;
    _sleepTicker = null;
    _sleepSecondsRemaining = 0;
    _sleepAfterCurrentSong = false;
    notifyListeners();
  }

  // Queue Management
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex) {
      next();
    }
    _queue.removeAt(index);
    if (_currentIndex > index) {
      _currentIndex--;
    }
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }

  void clearQueue() {
    final current = currentSong;
    _queue.clear();
    if (current != null) {
      _queue.add(current);
      _currentIndex = 0;
    } else {
      _currentIndex = -1;
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String songId) async {
    Song? song;
    try {
      song = _allSongs.firstWhere((s) => s.id == songId);
    } catch (_) {
      try {
        song = _queue.firstWhere((s) => s.id == songId);
      } catch (_) {
        song = currentSong;
      }
    }

    if (song != null) {
      await DatabaseService.instance.toggleFavorite(song);
      _favoriteIds.clear();
      _favoriteIds.addAll(DatabaseService.instance.favoriteIds);
      notifyListeners();
    } else {
      if (_favoriteIds.contains(songId)) {
        _favoriteIds.remove(songId);
      } else {
        _favoriteIds.add(songId);
      }
      notifyListeners();
    }
  }

  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  Future<void> clearPlaybackHistory() async {
    _recentlyPlayed.clear();
    await DatabaseService.instance.clearHistory();
    notifyListeners();
  }

  Future<void> clearAllUserData() async {
    _recentlyPlayed.clear();
    _favoriteIds.clear();
    _playlists.removeWhere((p) => p.type == PlaylistType.custom);
    await DatabaseService.instance.clearAllUserData();
    notifyListeners();
  }

  Future<Playlist> createPlaylist(
    String title, {
    String description = '',
  }) async {
    final newPlaylist = await DatabaseService.instance.createPlaylist(
      title,
      description: description,
    );
    _playlists.insert(0, newPlaylist);
    notifyListeners();
    return newPlaylist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    await DatabaseService.instance.deletePlaylist(playlistId);
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    Song? song;
    try {
      song = _allSongs.firstWhere((s) => s.id == songId);
    } catch (_) {
      try {
        song = _queue.firstWhere((s) => s.id == songId);
      } catch (_) {
        song = currentSong;
      }
    }

    if (song != null) {
      await DatabaseService.instance.addSongToPlaylist(playlistId, song);
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final p = _playlists[index];
        if (!p.songIds.contains(songId)) {
          _playlists[index] = p.copyWith(
            songIds: [...p.songIds, songId],
            songs: [...p.songs, song],
          );
          notifyListeners();
        }
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await DatabaseService.instance.removeSongFromPlaylist(playlistId, songId);
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final p = _playlists[index];
      _playlists[index] = p.copyWith(
        songIds: p.songIds.where((id) => id != songId).toList(),
        songs: p.songs.where((s) => s.id != songId).toList(),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
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
