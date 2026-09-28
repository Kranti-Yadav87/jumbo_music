import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'storage/storage_engine.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // In-memory active stores
  final Set<String> _favoriteIds = {};
  final Map<String, Song> _favoriteSongsMap = {};
  final List<Playlist> _customPlaylists = [];
  final Map<String, Map<String, dynamic>> _downloadsMap = {};
  final List<Map<String, dynamic>> _historyList = [];
  final Map<String, dynamic> _settings = {
    'autoplay': true,
    'soundPreset': 'Normal',
    'playbackSpeed': 1.0,
    'volume': 1.0,
    'isMuted': false,
    'incognitoMode': false,
    'highQuality': true,
  };

  // Storage Keys
  static const String _keyFavorites = 'jumbo_db_favorites';
  static const String _keyPlaylists = 'jumbo_db_playlists';
  static const String _keyDownloads = 'jumbo_db_downloads';
  static const String _keyHistory = 'jumbo_db_history';
  static const String _keySettings = 'jumbo_db_settings';

  /// Initialize database and load all stores into memory
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        _loadFavorites(),
        _loadPlaylists(),
        _loadDownloads(),
        _loadHistory(),
        _loadSettings(),
      ]);
    } catch (e) {
      debugPrint('DatabaseService init error: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // 1. FAVORITES STORE
  // -------------------------------------------------------------
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Song> get favoriteSongs => _favoriteSongsMap.values.toList();

  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  Future<void> _loadFavorites() async {
    try {
      final raw = await StorageEngine.getItem(_keyFavorites);
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
      await StorageEngine.setItem(_keyFavorites, jsonEncode(list));
    } catch (_) {}
  }

  Future<bool> toggleFavorite(Song song) async {
    final willFavorite = !_favoriteIds.contains(song.id);
    if (willFavorite) {
      _favoriteIds.add(song.id);
      _favoriteSongsMap[song.id] = song.copyWith(isFavorite: true);
    } else {
      _favoriteIds.remove(song.id);
      _favoriteSongsMap.remove(song.id);
    }
    notifyListeners();
    await _flushFavorites();
    return willFavorite;
  }

  // -------------------------------------------------------------
  // 2. PLAYLISTS STORE (Full CRUD)
  // -------------------------------------------------------------
  List<Playlist> get customPlaylists => List.unmodifiable(_customPlaylists);

  Future<void> _loadPlaylists() async {
    try {
      final raw = await StorageEngine.getItem(_keyPlaylists);
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
      await StorageEngine.setItem(_keyPlaylists, jsonEncode(list));
    } catch (_) {}
  }

  Future<Playlist> createPlaylist(String title, {String description = '', String coverUrl = ''}) async {
    final newId = 'pl_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = Playlist(
      id: newId,
      title: title.trim().isNotEmpty ? title.trim() : 'My Playlist',
      description: description.trim(),
      coverUrl: coverUrl.trim().isNotEmpty
          ? coverUrl.trim()
          : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      songIds: [],
      songs: [],
      type: PlaylistType.custom,
    );

    _customPlaylists.insert(0, playlist);
    notifyListeners();
    await _flushPlaylists();
    return playlist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    _customPlaylists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    await _flushPlaylists();
  }

  Future<bool> addSongToPlaylist(String playlistId, Song song) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return false;

    final target = _customPlaylists[idx];
    if (target.songIds.contains(song.id)) return false;

    final updatedSongIds = List<String>.from(target.songIds)..add(song.id);
    final updatedSongs = List<Song>.from(target.songs)..add(song);

    _customPlaylists[idx] = target.copyWith(
      songIds: updatedSongIds,
      songs: updatedSongs,
      coverUrl: target.coverUrl.isEmpty ? song.coverUrl : target.coverUrl,
    );

    notifyListeners();
    await _flushPlaylists();
    return true;
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    final target = _customPlaylists[idx];
    final updatedSongIds = List<String>.from(target.songIds)..remove(songId);
    final updatedSongs = List<Song>.from(target.songs)..removeWhere((s) => s.id == songId);

    _customPlaylists[idx] = target.copyWith(
      songIds: updatedSongIds,
      songs: updatedSongs,
    );

    notifyListeners();
    await _flushPlaylists();
  }

  Playlist? getPlaylistById(String playlistId) {
    try {
      return _customPlaylists.firstWhere((p) => p.id == playlistId);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // 3. DOWNLOADS STORE
  // -------------------------------------------------------------
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
      final raw = await StorageEngine.getItem(_keyDownloads);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _downloadsMap.clear();
        for (final item in list) {
          if (item is Map<String, dynamic> && item['songId'] != null) {
            _downloadsMap[item['songId'].toString()] = item;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _flushDownloads() async {
    try {
      final list = _downloadsMap.values.toList();
      await StorageEngine.setItem(_keyDownloads, jsonEncode(list));
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
    notifyListeners();
    await _flushDownloads();
  }

  Future<void> removeDownload(String songId) async {
    _downloadsMap.remove(songId);
    notifyListeners();
    await _flushDownloads();
  }

  // -------------------------------------------------------------
  // 4. LISTENING HISTORY STORE
  // -------------------------------------------------------------
  List<Map<String, dynamic>> get history => List.unmodifiable(_historyList);

  Future<void> _loadHistory() async {
    try {
      final raw = await StorageEngine.getItem(_keyHistory);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _historyList.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _historyList.add(item);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _flushHistory() async {
    try {
      await StorageEngine.setItem(_keyHistory, jsonEncode(_historyList));
    } catch (_) {}
  }

  Future<void> addHistory(Song song) async {
    // Respect Incognito Mode
    if (getSetting('incognitoMode', false) == true) {
      return;
    }

    _historyList.removeWhere((item) => item['songId'] == song.id);
    _historyList.insert(0, {
      'songId': song.id,
      'playedAt': DateTime.now().toIso8601String(),
      'song': song.toJson(),
    });

    if (_historyList.length > 100) {
      _historyList.removeRange(100, _historyList.length);
    }

    notifyListeners();
    await _flushHistory();
  }

  Future<void> clearHistory() async {
    _historyList.clear();
    notifyListeners();
    await _flushHistory();
  }

  // -------------------------------------------------------------
  // 5. SETTINGS STORE
  // -------------------------------------------------------------
  Map<String, dynamic> get settings => Map.unmodifiable(_settings);

  dynamic getSetting(String key, [dynamic defaultValue]) {
    return _settings.containsKey(key) ? _settings[key] : defaultValue;
  }

  Future<void> _loadSettings() async {
    try {
      final raw = await StorageEngine.getItem(_keySettings);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(raw);
        _settings.addAll(map);
      }
    } catch (_) {}
  }

  Future<void> updateSetting(String key, dynamic value) async {
    _settings[key] = value;
    notifyListeners();
    try {
      await StorageEngine.setItem(_keySettings, jsonEncode(_settings));
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // 6. GDPR DATA EXPORT & TOTAL WIPE
  // -------------------------------------------------------------
  Future<String> exportAllDataJson() async {
    final export = {
      'app': 'Jumbo Music',
      'exportedAt': DateTime.now().toIso8601String(),
      'favorites': _favoriteSongsMap.values.map((s) => s.toJson()).toList(),
      'customPlaylists': _customPlaylists.map((p) => p.toJson()).toList(),
      'downloads': _downloadsMap.values.toList(),
      'history': _historyList,
      'settings': _settings,
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  Future<void> clearAllUserData() async {
    _favoriteIds.clear();
    _favoriteSongsMap.clear();
    _customPlaylists.clear();
    _downloadsMap.clear();
    _historyList.clear();

    await Future.wait([
      StorageEngine.removeItem(_keyFavorites),
      StorageEngine.removeItem(_keyPlaylists),
      StorageEngine.removeItem(_keyDownloads),
      StorageEngine.removeItem(_keyHistory),
    ]);

    notifyListeners();
  }
}
