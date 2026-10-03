part of '../database_service.dart';

// -------------------------------------------------------------
// 2. PLAYLISTS STORE (Scoped Full CRUD) & 9. SHARED PLAYLISTS
// -------------------------------------------------------------
extension DatabaseServicePlaylists on DatabaseService {
  List<Playlist> get customPlaylists => List.unmodifiable(_customPlaylists);

  Future<void> _loadPlaylists() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('playlists'));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _customPlaylists.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _customPlaylists.add(Playlist.fromJson(item));
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _flushPlaylists() async {
    try {
      final list = _customPlaylists.map((p) => p.toJson()).toList();
      await StorageEngine.setItem(_scopedKey('playlists'), jsonEncode(list));
    } catch (_) {}
  }

  Future<void> addCustomPlaylist(
    Playlist playlist, {
    bool syncToCloud = true,
  }) async {
    _customPlaylists.removeWhere((p) => p.id == playlist.id);
    _customPlaylists.insert(0, playlist);
    notify();
    await _flushPlaylists();

    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushPlaylistToCloud(playlist);
    }
  }

  Future<Playlist> createPlaylist(
    String title, {
    String description = '',
    String coverUrl = '',
    bool syncToCloud = true,
  }) async {
    final newId = 'pl_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = Playlist(
      id: newId,
      title: title.trim().isNotEmpty ? title.trim() : 'My Playlist',
      description: description.trim(),
      coverUrl: coverUrl.trim().isNotEmpty
          ? coverUrl.trim()
          : 'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
      songIds: [],
      songs: [],
      type: PlaylistType.custom,
    );

    _customPlaylists.insert(0, playlist);
    notify();
    await _flushPlaylists();

    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushPlaylistToCloud(playlist);
    }
    return playlist;
  }

  Future<void> deletePlaylist(
    String playlistId, {
    bool syncToCloud = true,
  }) async {
    _customPlaylists.removeWhere((p) => p.id == playlistId);
    notify();
    await _flushPlaylists();

    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.deletePlaylistFromCloud(playlistId);
    }
  }

  Future<bool> addSongToPlaylist(
    String playlistId,
    Song song, {
    bool syncToCloud = true,
  }) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return false;

    final target = _customPlaylists[idx];
    if (target.songIds.contains(song.id)) return false;

    final updatedSongIds = List<String>.from(target.songIds)..add(song.id);
    final updatedSongs = List<Song>.from(target.songs)..add(song);

    final updatedPlaylist = target.copyWith(
      songIds: updatedSongIds,
      songs: updatedSongs,
      coverUrl: target.coverUrl.isEmpty ? song.coverUrl : target.coverUrl,
    );

    _customPlaylists[idx] = updatedPlaylist;
    notify();
    await _flushPlaylists();

    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushPlaylistToCloud(updatedPlaylist);
    }
    return true;
  }

  Future<void> removeSongFromPlaylist(
    String playlistId,
    String songId, {
    bool syncToCloud = true,
  }) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    final target = _customPlaylists[idx];
    final updatedSongIds = List<String>.from(target.songIds)..remove(songId);
    final updatedSongs = List<Song>.from(target.songs)
      ..removeWhere((s) => s.id == songId);

    final updatedPlaylist = target.copyWith(
      songIds: updatedSongIds,
      songs: updatedSongs,
    );

    _customPlaylists[idx] = updatedPlaylist;
    notify();
    await _flushPlaylists();

    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushPlaylistToCloud(updatedPlaylist);
    }
  }

  Playlist? getPlaylistById(String playlistId) {
    try {
      return _customPlaylists.firstWhere((p) => p.id == playlistId);
    } catch (_) {
      return null;
    }
  }

  List<Playlist> get sharedPlaylists => _customPlaylists
      .where((p) => p.isCollaborative || p.type == PlaylistType.sharedBlend)
      .toList();

  Future<Playlist> createSharedBlendPlaylist({
    required String title,
    required Friend friend,
    List<Song> starterSongs = const [],
  }) async {
    final newId = 'blend_${DateTime.now().millisecondsSinceEpoch}';
    final playlistTitle = title.trim().isNotEmpty
        ? title.trim()
        : '$_userName + ${friend.name} Blend';

    final playlist = Playlist(
      id: newId,
      title: playlistTitle,
      description: 'Shared Blend with ${friend.name} (${friend.email})',
      coverUrl: starterSongs.isNotEmpty
          ? starterSongs.first.coverUrl
          : (friend.currentSongCover.isNotEmpty
                ? friend.currentSongCover
                : 'https://c.saavncdn.com/editorial/charts_EnglishTopSongs_500x500.jpg'),
      songIds: starterSongs.map((s) => s.id).toList(),
      songs: starterSongs,
      type: PlaylistType.sharedBlend,
      isCollaborative: true,
      collaboratorNames: [_userName, friend.name],
      friendEmail: friend.email,
    );

    _customPlaylists.insert(0, playlist);

    addNotification(
      title: 'Shared Playlist Created',
      message:
          'You and ${friend.name} can now add and listen to songs together in "$playlistTitle"!',
      type: 'playlist',
    );

    notify();
    await _flushPlaylists();
    return playlist;
  }

  Future<void> addSongToSharedPlaylist(String playlistId, Song song) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final pl = _customPlaylists[idx];
      if (!pl.songIds.contains(song.id)) {
        final updatedSongIds = List<String>.from(pl.songIds)..add(song.id);
        final updatedSongs = List<Song>.from(pl.songs)..add(song);
        final updatedCover = pl.coverUrl.isEmpty ? song.coverUrl : pl.coverUrl;

        _customPlaylists[idx] = pl.copyWith(
          songIds: updatedSongIds,
          songs: updatedSongs,
          coverUrl: updatedCover,
        );

        addNotification(
          title: 'Song Added to Shared Playlist',
          message: '"${song.title}" was added to "${pl.title}"',
          type: 'playlist',
        );

        notify();
        await _flushPlaylists();
      }
    }
  }
}
