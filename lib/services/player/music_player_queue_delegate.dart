part of '../music_player_manager.dart';

extension MusicPlayerQueueDelegate on MusicPlayerManager {
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex) {
      next();
    }
    _queue.removeAt(index);
    if (_currentIndex > index) {
      _currentIndex--;
    }
    notify();
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
    notify();
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
        final Set<String> currentQueueKeys =
            _queue.map(SongParserUtils.songDeduplicationKey).toSet();

        final localCandidates = _allSongs.where((s) {
          if (currentQueueIds.contains(s.id)) return false;
          final key = SongParserUtils.songDeduplicationKey(s);
          if (currentQueueKeys.contains(key)) return false;

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
          final dedupedLocal = SongParserUtils.deduplicateSongs(localCandidates);
          _queue.addAll(dedupedLocal.take(needed));
          _queue = SongParserUtils.deduplicateSongs(_queue);
          notify();
        }
      }

      // 2. Fetch fresh smart recommendations concurrently matching exact era and language
      final freshTracks = await MusicApiService.fetchSmartRecommendations(
        seedSong,
        limit: 55,
      );
      if (freshTracks.isNotEmpty) {
        final currentQueueIds = _queue.map((s) => s.id).toSet();
        final currentQueueKeys =
            _queue.map(SongParserUtils.songDeduplicationKey).toSet();

        final List<Song> dedupedFresh = SongParserUtils.deduplicateSongs(
          freshTracks,
        );
        final List<Song> newTracks = dedupedFresh.where((s) {
          if (currentQueueIds.contains(s.id)) return false;
          final key = SongParserUtils.songDeduplicationKey(s);
          if (currentQueueKeys.contains(key)) return false;
          return true;
        }).toList();

        if (newTracks.isNotEmpty) {
          final playedPart = _queue.sublist(0, _currentIndex + 1);
          final upcomingPart = _queue.sublist(_currentIndex + 1);

          final Set<String> freshKeys =
              newTracks.map(SongParserUtils.songDeduplicationKey).toSet();
          final remainingUpcoming = upcomingPart.where((s) {
            final key = SongParserUtils.songDeduplicationKey(s);
            if (freshKeys.contains(key)) return false;

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

          _queue = SongParserUtils.deduplicateSongs([
            ...playedPart,
            ...newTracks,
            ...remainingUpcoming,
          ]).take(targetQueueSize).toList();

          // Add to allSongs as well
          final Set<String> allKeys =
              _allSongs.map(SongParserUtils.songDeduplicationKey).toSet();
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
