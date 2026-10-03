part of '../music_player_manager.dart';

extension MusicPlayerLibrarySync on MusicPlayerManager {
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
    _playlists.insert(0, newPlaylist);
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
