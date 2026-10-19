part of '../music_player_manager.dart';

extension MusicPlayerLibrarySync on MusicPlayerManager {
  void _updateDynamicLibrary(Song song) {
    // Recently Played (up to 40) - Skipped if Incognito Mode is active for privacy
    if (!PrivacySecurityService().isIncognitoMode) {
      _recentlyPlayed.removeWhere((s) => s.id == song.id);
      _recentlyPlayed.insert(0, song);
      if (_recentlyPlayed.length > 40) {
        _recentlyPlayed.removeLast();
      }
    }
    // Automatic creation of Artist Mix, Genre Station, and Daily Smart Mix
    // is completely disabled so playlists are only created manually by user via '+'.
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
      notify();
    } else {
      if (_favoriteIds.contains(songId)) {
        _favoriteIds.remove(songId);
      } else {
        _favoriteIds.add(songId);
      }
      notify();
    }
  }

  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  Future<void> clearPlaybackHistory() async {
    _recentlyPlayed.clear();
    await DatabaseService.instance.clearHistory();
    notify();
  }

  Future<void> clearAllUserData() async {
    _recentlyPlayed.clear();
    _favoriteIds.clear();
    _playlists.removeWhere((p) => p.type == PlaylistType.custom);
    _currentSong = null;
    _queue.clear();
    _currentIndex = -1;
    await DatabaseService.instance.clearAllUserData();
    notify();
  }

  Future<Playlist> createPlaylist(
    String title, {
    String description = '',
  }) async {
    final newPlaylist = await DatabaseService.instance.createPlaylist(
      title,
      description: description,
    );
    if (!_playlists.any((p) => p.id == newPlaylist.id)) {
      _playlists.insert(0, newPlaylist);
    }
    notify();
    return newPlaylist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    await DatabaseService.instance.deletePlaylist(playlistId);
    _playlists.removeWhere((p) => p.id == playlistId);
    notify();
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
          notify();
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
      notify();
    }
  }
}
