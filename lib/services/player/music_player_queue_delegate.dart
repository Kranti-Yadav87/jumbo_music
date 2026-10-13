part of '../music_player_manager.dart';

extension MusicPlayerQueueDelegate on MusicPlayerManager {
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex) {
      next();
    }
    _queue.removeAt(index);
    if (_playlistSource != null && index < _playlistSource!.length) {
      try {
        _playlistSource!.removeAt(index);
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
    if (_playlistSource != null &&
        oldIndex < _playlistSource!.length &&
        newIndex < _playlistSource!.length) {
      try {
        _playlistSource!.move(oldIndex, newIndex);
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
      if (_playlistSource != null && _playlistSource!.length > 1) {
        try {
          while (_playlistSource!.length > 1) {
            _playlistSource!.removeAt(_playlistSource!.length - 1);
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
    final Set<String> currentQueueIds = _queue.map((s) => s.id).toSet();
    final Set<String> currentQueueKeys = _queue
        .map(SongParserUtils.songDeduplicationKey)
        .toSet();

    for (final track in tracks) {
      if (track.audioUrl.trim().isEmpty) continue;
      if (track.duration.inSeconds > 0 && track.duration.inSeconds < 60) {
        continue;
      }
      if (currentQueueIds.contains(track.id)) continue;
      final key = SongParserUtils.songDeduplicationKey(track);
      if (currentQueueKeys.contains(key)) continue;

      currentQueueIds.add(track.id);
      currentQueueKeys.add(key);
      _queue.add(track);

      if (_playlistSource != null) {
        try {
          final mediaItem = MediaItem(
            id: track.id,
            album: track.album.isNotEmpty ? track.album : 'Jumbo Music',
            title: track.title.isNotEmpty ? track.title : 'Unknown Title',
            artist: track.artist.isNotEmpty ? track.artist : 'Unknown Artist',
            artUri: track.coverUrl.isNotEmpty
                ? Uri.tryParse(track.coverUrl)
                : null,
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
          _playlistSource!.add(
            AudioSource.uri(Uri.parse(track.audioUrl), tag: mediaItem),
          );
        } catch (e) {
          debugPrint('[QueueSync] Error adding source to _playlistSource: $e');
        }
      }
    }
    _syncCurrentSongAndIndex();
    notify();
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
    notify();

    try {
      final smartTracks = await AiRecommendationEngine.instance.buildSmartQueue(
        seedSong: seedSong,
        existingQueue: _queue,
        targetSize: targetQueueSize,
      );

      if (smartTracks.isNotEmpty) {
        final currentQueueIds = _queue.map((s) => s.id).toSet();
        final currentQueueKeys = _queue
            .map(SongParserUtils.songDeduplicationKey)
            .toSet();

        final List<Song> newTracks = smartTracks.where((s) {
          if (s.id == seedSong.id) return false;
          if (s.audioUrl.trim().isEmpty) return false;
          if (currentQueueIds.contains(s.id)) return false;
          if (s.duration.inSeconds > 0 && s.duration.inSeconds < 60) {
            return false;
          }
          final key = SongParserUtils.songDeduplicationKey(s);
          if (currentQueueKeys.contains(key)) return false;
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
        }
      }
    } catch (error) {
      CrashReportingService.swallow(
        error,
        'music_player_queue_delegate.dart:212',
      );
    }

    _isLoadingRecommendations = false;
    notify();
  }
}
