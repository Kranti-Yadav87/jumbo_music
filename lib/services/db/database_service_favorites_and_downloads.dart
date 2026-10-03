part of '../database_service.dart';

// -------------------------------------------------------------
// 1. FAVORITES STORE (Scoped)
// -------------------------------------------------------------
extension DatabaseServiceFavorites on DatabaseService {
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Song> get favoriteSongs => _favoriteSongsMap.values.toList();

  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  Future<void> _loadFavorites() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('favorites'));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _favoriteIds.clear();
        _favoriteSongsMap.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final song = Song.fromJson(item);
            _favoriteIds.add(song.id);
            _favoriteSongsMap[song.id] = song;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _flushFavorites() async {
    try {
      final list = _favoriteSongsMap.values.map((s) => s.toJson()).toList();
      await StorageEngine.setItem(_scopedKey('favorites'), jsonEncode(list));
    } catch (_) {}
  }

  Future<bool> toggleFavorite(Song song, {bool syncToCloud = true}) async {
    final willFavorite = !_favoriteIds.contains(song.id);
    if (willFavorite) {
      _favoriteIds.add(song.id);
      _favoriteSongsMap[song.id] = song.copyWith(isFavorite: true);
    } else {
      _favoriteIds.remove(song.id);
      _favoriteSongsMap.remove(song.id);
    }
    notify();
    await _flushFavorites();

    // Cloud sync only runs for authenticated users
    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushFavoriteToCloud(song, willFavorite);
    }
    return willFavorite;
  }
}

// -------------------------------------------------------------
// 3. DOWNLOADS STORE (Scoped)
// -------------------------------------------------------------
extension DatabaseServiceDownloads on DatabaseService {
  List<Map<String, dynamic>> get rawDownloads => _downloadsMap.values.toList();

  List<Song> get downloadedSongs {
    final list = <Song>[];
    for (final item in _downloadsMap.values) {
      if (item['song'] != null && item['song'] is Map<String, dynamic>) {
        list.add(Song.fromJson(item['song'] as Map<String, dynamic>));
      }
    }
    return list;
  }

  bool isDownloaded(String songId) => _downloadsMap.containsKey(songId);

  String? getDownloadedFileSize(String songId) =>
      _downloadsMap[songId]?['fileSize'] as String?;

  Future<void> _loadDownloads() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('downloads'));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _downloadsMap.clear();
        for (final item in list) {
          if (item is Map<String, dynamic> && item['songId'] != null) {
            final songId = item['songId'].toString();
            final songData = item['song'] as Map<String, dynamic>?;
            final title = songData?['title']?.toString() ?? '';
            if (songId == 'dl_1' ||
                songId == 'dl_2' ||
                songId.startsWith('sample_') ||
                title == 'Kesariya Sukoon' ||
                title == 'Midnight Lo-Fi Chill') {
              continue;
            }
            _downloadsMap[songId] = item;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _flushDownloads() async {
    try {
      final list = _downloadsMap.values.toList();
      await StorageEngine.setItem(_scopedKey('downloads'), jsonEncode(list));
    } catch (_) {}
  }

  Future<void> saveDownload({
    required Song song,
    required String fileSize,
    required String localPath,
  }) async {
    _downloadsMap[song.id] = {
      'songId': song.id,
      'fileSize': fileSize,
      'localPath': localPath,
      'downloadedAt': DateTime.now().toIso8601String(),
      'song': song.toJson(),
    };
    notify();
    await _flushDownloads();
  }

  Future<void> removeDownload(String songId) async {
    _downloadsMap.remove(songId);
    notify();
    await _flushDownloads();
  }
}
