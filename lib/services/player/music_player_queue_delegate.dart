part of '../music_player_manager.dart';

extension MusicPlayerQueueDelegate on MusicPlayerManager {
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex) {
      next();
    }
    _queue.removeAt(index);
    if (!kIsWeb && _playlistSource != null && index < _playlistSource!.length) {
      try {
        unawaited(
          _playlistSource!.removeAt(index).catchError((e) {
            debugPrint(
              '[QueueSync] Error removing index $index from _playlistSource: $e',
            );
          }),
        );
      } catch (e) {
        debugPrint(
          '[QueueSync] Error removing index $index from _playlistSource: $e',
        );
      }
    }
    _syncCurrentSongAndIndex();
    notify();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    if (!kIsWeb &&
        _playlistSource != null &&
        oldIndex < _playlistSource!.length &&
        newIndex < _playlistSource!.length) {
      try {
        unawaited(
          _playlistSource!.move(oldIndex, newIndex).catchError((e) {
            debugPrint('[QueueSync] Error moving index in _playlistSource: $e');
          }),
        );
      } catch (e) {
        debugPrint('[QueueSync] Error moving index in _playlistSource: $e');
      }
    }
    _syncCurrentSongAndIndex();
    notify();
  }

  void clearQueue() {
    final current = currentSong;
    _queue.clear();
    if (current != null) {
      _queue.add(current);
      _currentSong = current;
      _currentIndex = 0;
      if (!kIsWeb && _playlistSource != null && _playlistSource!.length > 1) {
        try {
          while (_playlistSource!.length > 1) {
            unawaited(
              _playlistSource!
                  .removeAt(_playlistSource!.length - 1)
                  .catchError((_) {}),
            );
          }
        } catch (_) {}
      }
    } else {
      _currentSong = null;
      _currentIndex = -1;
      _playlistSource?.clear();
    }
    notify();
  }

  /// Appends tracks to the queue while keeping native ConcatenatingAudioSource 100% in sync.
  /// Prevents desynchronization between what is displayed in the queue and what actually plays.
  void _appendTracksToQueueAndPlaylistSource(List<Song> tracks) {
    final seedLang = currentSong != null
        ? MusicApiService.detectSongLanguage(currentSong!)
        : null;
    final seedEra = currentSong != null
        ? MusicTagClassifier.detectSongEra(currentSong!)
        : null;
    final Set<String> currentQueueIds = _queue.map((s) => s.id).toSet();
    final Set<String> currentQueueKeys = _queue
        .map(SongParserUtils.songDeduplicationKey)
        .toSet();
    if (currentSong != null) {
      currentQueueIds.add(currentSong!.id);
      currentQueueKeys.add(SongParserUtils.songDeduplicationKey(currentSong!));
    }

    for (final track in tracks) {
      if (track.audioUrl.trim().isEmpty) continue;
      if (track.audioUrl.contains('apple.com') ||
          track.audioUrl.contains('mzstatic.com') ||
          track.audioUrl.contains('preview')) {
        continue;
      }
      if (track.duration.inSeconds > 0 && track.duration.inSeconds < 75) {
        continue;
      }
      if (seedLang != null &&
          MusicApiService.detectSongLanguage(track) != seedLang) {
        continue;
      }
      if (seedLang != null) {
        if (seedLang != 'English' && MusicTagClassifier.isEnglishSong(track)) {
          continue;
        }
        if (seedLang == 'English' && !MusicTagClassifier.isEnglishSong(track)) {
          continue;
        }
      }
      if (seedEra != null &&
          MusicTagClassifier.detectSongEra(track) != seedEra) {
        continue;
      }
      if (currentQueueIds.contains(track.id)) continue;
      final key = SongParserUtils.songDeduplicationKey(track);
      if (currentQueueKeys.contains(key)) continue;
      if (_queue.any(
        (s) =>
            s.id == track.id || SongParserUtils.songDeduplicationKey(s) == key,
      )) {
        continue;
      }

      currentQueueIds.add(track.id);
      currentQueueKeys.add(key);
      _queue.add(track);

      if (!kIsWeb && _playlistSource != null && !_isTransitioning) {
        try {
          final trackCover = track.coverUrl.trim();
          final trackSecureCover = trackCover.startsWith('http://')
              ? trackCover.replaceFirst('http://', 'https://')
              : trackCover;
          final Uri? trackArtUri;
          if (trackSecureCover.startsWith('file://')) {
            trackArtUri = Uri.parse(trackSecureCover);
          } else if (trackSecureCover.startsWith('/') &&
              !trackSecureCover.startsWith('//')) {
            trackArtUri = Uri.file(trackSecureCover);
          } else if (trackSecureCover.isNotEmpty) {
            trackArtUri = Uri.tryParse(trackSecureCover);
          } else {
            trackArtUri = null;
          }

          final mediaItem = MediaItem(
            id: track.id,
            album: track.album.isNotEmpty ? track.album : 'Jumbo Music',
            title: track.title.isNotEmpty ? track.title : 'Unknown Title',
            artist: track.artist.isNotEmpty ? track.artist : 'Unknown Artist',
            artUri: trackArtUri,
            duration: track.duration.inSeconds > 0 ? track.duration : null,
            playable: true,
            displayTitle: track.title.isNotEmpty
                ? track.title
                : 'Unknown Title',
            displaySubtitle: track.artist.isNotEmpty
                ? track.artist
                : 'Unknown Artist',
            displayDescription: track.album.isNotEmpty
                ? track.album
                : 'Jumbo Music',
          );
          unawaited(
            _playlistSource!
                .add(AudioSource.uri(Uri.parse(track.audioUrl), tag: mediaItem))
                .catchError((e) {
                  debugPrint(
                    '[QueueSync] Error adding source to _playlistSource: $e',
                  );
                }),
          );
        } catch (e) {
          debugPrint('[QueueSync] Error adding source to _playlistSource: $e');
        }
      }
    }
    _queue = SongParserUtils.deduplicateSongs(_queue);
    _syncCurrentSongAndIndex();
    notify();
  }

  Future<void> _infillSmartQueue(
    Song seedSong, {
    int targetQueueSize = 60,
  }) async {
    if (!_autoplay || _isQueueLocked) return;

    if (_isLoadingRecommendations) {
      if (_infillCompleter != null && !_infillCompleter!.isCompleted) {
        try {
          await _infillCompleter!.future.timeout(const Duration(seconds: 4));
        } catch (_) {}
      }
      return;
    }

    if (_lastInfilledSongId == seedSong.id &&
        _queue.length >= targetQueueSize) {
      return;
    }
    _lastInfilledSongId = seedSong.id;

    _isLoadingRecommendations = true;
    _infillCompleter = Completer<void>();
    notify();

    try {
      final seedLang = MusicApiService.detectSongLanguage(seedSong);
      final seedEra = MusicTagClassifier.detectSongEra(seedSong);
      final smartTracks = await AiRecommendationEngine.instance.buildSmartQueue(
        seedSong: seedSong,
        existingQueue: _queue,
        targetSize: targetQueueSize,
      );

      if (smartTracks.isNotEmpty) {
        _queue = SongParserUtils.deduplicateSongs(_queue);
        final currentQueueIds = _queue.map((s) => s.id).toSet()
          ..add(seedSong.id);
        final currentQueueKeys =
            _queue.map(SongParserUtils.songDeduplicationKey).toSet()
              ..add(SongParserUtils.songDeduplicationKey(seedSong));

        final List<Song> newTracks = smartTracks.where((s) {
          if (s.id == seedSong.id) return false;
          if (s.audioUrl.trim().isEmpty) return false;
          if (s.audioUrl.contains('apple.com') ||
              s.audioUrl.contains('mzstatic.com') ||
              s.audioUrl.contains('preview')) {
            return false;
          }
          if (s.duration.inSeconds > 0 && s.duration.inSeconds < 75) {
            return false;
          }
          if (MusicApiService.detectSongLanguage(s) != seedLang) {
            return false;
          }
          if (seedLang != 'English' && MusicTagClassifier.isEnglishSong(s)) {
            return false;
          }
          if (seedLang == 'English' && !MusicTagClassifier.isEnglishSong(s)) {
            return false;
          }
          if (MusicTagClassifier.detectSongEra(s) != seedEra) {
            return false;
          }
          if (currentQueueIds.contains(s.id)) return false;
          final key = SongParserUtils.songDeduplicationKey(s);
          if (currentQueueKeys.contains(key)) return false;
          if (_queue.any(
            (q) =>
                q.id == s.id || SongParserUtils.songDeduplicationKey(q) == key,
          )) {
            return false;
          }
          currentQueueIds.add(s.id);
          currentQueueKeys.add(key);
          return true;
        }).toList();

        if (newTracks.isNotEmpty) {
          _appendTracksToQueueAndPlaylistSource(newTracks);

          // Add to allSongs as well
          final Set<String> allKeys = _allSongs
              .map(SongParserUtils.songDeduplicationKey)
              .toSet();
          for (final track in newTracks) {
            final key = SongParserUtils.songDeduplicationKey(track);
            if (!allKeys.contains(key)) {
              _allSongs.add(track);
              allKeys.add(key);
            }
          }
          _queue = SongParserUtils.deduplicateSongs(_queue);
          _syncCurrentSongAndIndex();
        }
      }
    } catch (error) {
      CrashReportingService.swallow(
        error,
        'music_player_queue_delegate.dart:212',
      );
    } finally {
      _isLoadingRecommendations = false;
      if (_infillCompleter != null && !_infillCompleter!.isCompleted) {
        _infillCompleter!.complete();
      }
      _infillCompleter = null;
      notify();
    }
  }
}
