import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/friend.dart';
import 'storage/storage_engine.dart';
import 'firestore_sync_service.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Active user storage scope: 'guest' or 'user_${uid}'
  String _currentScope = 'guest';
  String get currentScope => _currentScope;

  // In-memory active stores
  final Set<String> _favoriteIds = {};
  final Map<String, Song> _favoriteSongsMap = {};
  final List<Playlist> _customPlaylists = [];
  final Map<String, Map<String, dynamic>> _downloadsMap = {};
  final List<Map<String, dynamic>> _historyList = [];
  final List<String> _searchHistory = [];
  final List<Friend> _friends = [];
  final List<Map<String, dynamic>> _notifications = [];

  // User Profile & Authentication
  bool _isLoggedIn = false;
  String _userId = '';
  String _userEmail = 'guest.listener@jumbomusic.app';
  String _userName = 'Guest Explorer';
  String _userAvatarUrl = '';
  String _userBio = 'Music Lover • Jumbo Listener';

  final Map<String, dynamic> _settings = {
    'autoplay': true,
    'soundPreset': 'Normal',
    'playbackSpeed': 1.0,
    'volume': 1.0,
    'isMuted': false,
    'incognitoMode': false,
    'highQuality': true,
  };

  // Helper for generating UID-scoped keys
  String _scopedKey(String suffix) => 'jumbo_${_currentScope}_$suffix';

  /// Initialize database and load all stores into memory
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Migrate legacy unscoped keys to guest scope on first run
      await _migrateLegacyKeysIfNeeded();

      // 2. Load scoped stores
      await _loadAllStores();
    } catch (e) {
      debugPrint('DatabaseService init error: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Safe migration of legacy single-key storage to scoped guest storage
  Future<void> _migrateLegacyKeysIfNeeded() async {
    try {
      final legacyFavs = await StorageEngine.getItem('jumbo_db_favorites');
      if (legacyFavs != null && legacyFavs.isNotEmpty) {
        final existingGuestFavs = await StorageEngine.getItem(
          'jumbo_guest_favorites',
        );
        if (existingGuestFavs == null) {
          await StorageEngine.setItem('jumbo_guest_favorites', legacyFavs);
        }
        await StorageEngine.removeItem('jumbo_db_favorites');
      }

      final legacyPlaylists = await StorageEngine.getItem('jumbo_db_playlists');
      if (legacyPlaylists != null && legacyPlaylists.isNotEmpty) {
        final existingGuestPlaylists = await StorageEngine.getItem(
          'jumbo_guest_playlists',
        );
        if (existingGuestPlaylists == null) {
          await StorageEngine.setItem('jumbo_guest_playlists', legacyPlaylists);
        }
        await StorageEngine.removeItem('jumbo_db_playlists');
      }

      final legacyDownloads = await StorageEngine.getItem('jumbo_db_downloads');
      if (legacyDownloads != null && legacyDownloads.isNotEmpty) {
        final existingGuestDownloads = await StorageEngine.getItem(
          'jumbo_guest_downloads',
        );
        if (existingGuestDownloads == null) {
          await StorageEngine.setItem('jumbo_guest_downloads', legacyDownloads);
        }
        await StorageEngine.removeItem('jumbo_db_downloads');
      }

      final legacyHistory = await StorageEngine.getItem('jumbo_db_history');
      if (legacyHistory != null && legacyHistory.isNotEmpty) {
        final existingGuestHistory = await StorageEngine.getItem(
          'jumbo_guest_history',
        );
        if (existingGuestHistory == null) {
          await StorageEngine.setItem('jumbo_guest_history', legacyHistory);
        }
        await StorageEngine.removeItem('jumbo_db_history');
      }

      final legacySearch = await StorageEngine.getItem(
        'jumbo_db_search_history',
      );
      if (legacySearch != null && legacySearch.isNotEmpty) {
        final existingGuestSearch = await StorageEngine.getItem(
          'jumbo_guest_search_history',
        );
        if (existingGuestSearch == null) {
          await StorageEngine.setItem(
            'jumbo_guest_search_history',
            legacySearch,
          );
        }
        await StorageEngine.removeItem('jumbo_db_search_history');
      }

      final legacyProfile = await StorageEngine.getItem('jumbo_db_profile');
      if (legacyProfile != null && legacyProfile.isNotEmpty) {
        final existingGuestProfile = await StorageEngine.getItem(
          'jumbo_guest_profile',
        );
        if (existingGuestProfile == null) {
          await StorageEngine.setItem('jumbo_guest_profile', legacyProfile);
        }
        await StorageEngine.removeItem('jumbo_db_profile');
      }

      final legacyFriends = await StorageEngine.getItem('jumbo_db_friends');
      if (legacyFriends != null && legacyFriends.isNotEmpty) {
        final existingGuestFriends = await StorageEngine.getItem(
          'jumbo_guest_friends',
        );
        if (existingGuestFriends == null) {
          await StorageEngine.setItem('jumbo_guest_friends', legacyFriends);
        }
        await StorageEngine.removeItem('jumbo_db_friends');
      }

      final legacyNotifications = await StorageEngine.getItem(
        'jumbo_db_notifications',
      );
      if (legacyNotifications != null && legacyNotifications.isNotEmpty) {
        final existingGuestNotifications = await StorageEngine.getItem(
          'jumbo_guest_notifications',
        );
        if (existingGuestNotifications == null) {
          await StorageEngine.setItem(
            'jumbo_guest_notifications',
            legacyNotifications,
          );
        }
        await StorageEngine.removeItem('jumbo_db_notifications');
      }
    } catch (e) {
      debugPrint('Legacy migration note: $e');
    }
  }

  /// Switch the active user storage scope.
  /// If uid is null or empty, switches to "guest".
  Future<void> switchUserScope(String? uid) async {
    final newScope = (uid != null && uid.trim().isNotEmpty)
        ? 'user_${uid.trim()}'
        : 'guest';
    if (_currentScope == newScope && _isInitialized) {
      return;
    }
    _currentScope = newScope;
    _clearMemoryStores();
    await _loadAllStores();
    notifyListeners();
  }

  void _clearMemoryStores() {
    _favoriteIds.clear();
    _favoriteSongsMap.clear();
    _customPlaylists.clear();
    _downloadsMap.clear();
    _historyList.clear();
    _searchHistory.clear();
    _friends.clear();
    _notifications.clear();
  }

  Future<void> _loadAllStores() async {
    await Future.wait([
      _loadFavorites(),
      _loadPlaylists(),
      _loadDownloads(),
      _loadHistory(),
      _loadSearchHistory(),
      _loadSettings(),
      _loadProfile(),
      _loadFriends(),
      _loadNotifications(),
    ]);
  }

  // -------------------------------------------------------------
  // 1. FAVORITES STORE (Scoped)
  // -------------------------------------------------------------
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
    notifyListeners();
    await _flushFavorites();

    // Cloud sync only runs for authenticated users
    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushFavoriteToCloud(song, willFavorite);
    }
    return willFavorite;
  }

  // -------------------------------------------------------------
  // 2. PLAYLISTS STORE (Scoped Full CRUD)
  // -------------------------------------------------------------
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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

  // -------------------------------------------------------------
  // 3. DOWNLOADS STORE (Scoped)
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
    notifyListeners();
    await _flushDownloads();
  }

  Future<void> removeDownload(String songId) async {
    _downloadsMap.remove(songId);
    notifyListeners();
    await _flushDownloads();
  }

  // -------------------------------------------------------------
  // 4. LISTENING HISTORY STORE (Scoped)
  // -------------------------------------------------------------
  List<Map<String, dynamic>> get history => List.unmodifiable(_historyList);

  Future<void> _loadHistory() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('history'));
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
      await StorageEngine.setItem(
        _scopedKey('history'),
        jsonEncode(_historyList),
      );
    } catch (_) {}
  }

  Future<void> addHistory(Song song, {bool syncToCloud = true}) async {
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

    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushHistoryToCloud(song);
    }
  }

  Future<void> addToHistory(Song song, {bool syncToCloud = true}) =>
      addHistory(song, syncToCloud: syncToCloud);

  Future<void> clearHistory() async {
    _historyList.clear();
    notifyListeners();
    await _flushHistory();
  }

  // -------------------------------------------------------------
  // 5. SEARCH HISTORY STORE (Scoped)
  // -------------------------------------------------------------
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  Future<void> _loadSearchHistory() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('search_history'));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _searchHistory.clear();
        for (final item in list) {
          if (item is String && item.trim().isNotEmpty) {
            _searchHistory.add(item.trim());
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _flushSearchHistory() async {
    try {
      await StorageEngine.setItem(
        _scopedKey('search_history'),
        jsonEncode(_searchHistory),
      );
    } catch (_) {}
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    if (getSetting('incognitoMode', false) == true) return;

    _searchHistory.removeWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    _searchHistory.insert(0, trimmed);

    if (_searchHistory.length > 25) {
      _searchHistory.removeRange(25, _searchHistory.length);
    }

    notifyListeners();
    await _flushSearchHistory();
  }

  Future<void> removeSearchQuery(String query) async {
    _searchHistory.removeWhere(
      (item) => item.toLowerCase() == query.trim().toLowerCase(),
    );
    notifyListeners();
    await _flushSearchHistory();
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();
    await _flushSearchHistory();
  }

  // -------------------------------------------------------------
  // 6. SETTINGS STORE (Scoped)
  // -------------------------------------------------------------
  Map<String, dynamic> get settings => Map.unmodifiable(_settings);

  dynamic getSetting(String key, [dynamic defaultValue]) {
    return _settings.containsKey(key) ? _settings[key] : defaultValue;
  }

  Future<void> _loadSettings() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('settings'));
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
      await StorageEngine.setItem(
        _scopedKey('settings'),
        jsonEncode(_settings),
      );
    } catch (_) {}
  }

  Future<void> saveSetting(String key, dynamic value) =>
      updateSetting(key, value);

  // -------------------------------------------------------------
  // 7. USER PROFILE & AUTHENTICATION STORE (Scoped)
  // -------------------------------------------------------------
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId.isNotEmpty
      ? _userId
      : 'JM-${(_userEmail.hashCode.abs() % 90000 + 10000)}';
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userAvatarUrl => _userAvatarUrl;
  String get userBio => _userBio;

  String get userInitials {
    if (_userName.trim().isNotEmpty) {
      final parts = _userName.trim().split(' ');
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return _userName.trim()[0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _loadProfile() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('profile'));
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _isLoggedIn = data['isLoggedIn'] as bool? ?? false;
        _userId = data['userId'] as String? ?? '';
        _userName =
            data['name'] as String? ??
            (_isLoggedIn ? 'User' : 'Guest Explorer');
        _userEmail =
            data['email'] as String? ??
            (_isLoggedIn
                ? 'user@jumbomusic.app'
                : 'guest.listener@jumbomusic.app');
        _userAvatarUrl = data['avatarUrl'] as String? ?? '';
        _userBio = data['bio'] as String? ?? 'Music Lover • Jumbo Pro';
      }
    } catch (_) {}
  }

  Future<void> _flushProfile() async {
    try {
      final map = {
        'isLoggedIn': _isLoggedIn,
        'userId': _userId,
        'name': _userName,
        'email': _userEmail,
        'avatarUrl': _userAvatarUrl,
        'bio': _userBio,
      };
      await StorageEngine.setItem(_scopedKey('profile'), jsonEncode(map));
    } catch (_) {}
  }

  Future<void> login({
    required String email,
    required String name,
    String? password,
    String? userId,
    String? uid,
  }) async {
    _isLoggedIn = true;
    _userEmail = email.trim();
    _userName = name.trim().isNotEmpty ? name.trim() : email.split('@').first;
    _userId = userId ?? 'JM-${(_userEmail.hashCode.abs() % 90000 + 10000)}';

    // Switch storage scope to UID (or generated userId)
    final targetScope = (uid != null && uid.isNotEmpty) ? uid : _userId;
    await switchUserScope(targetScope);

    await _flushProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = 'Guest Explorer';
    _userEmail = 'guest.listener@jumbomusic.app';
    _userId = '';
    _userAvatarUrl = '';
    _userBio = 'Music Lover • Jumbo Listener';

    // Switch storage scope back to guest without clearing the previous user's files
    await switchUserScope(null);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
  }) async {
    if (name != null) _userName = name.trim();
    if (email != null) _userEmail = email.trim();
    if (avatarUrl != null) _userAvatarUrl = avatarUrl.trim();
    if (bio != null) _userBio = bio.trim();

    notifyListeners();
    await _flushProfile();
  }

  // -------------------------------------------------------------
  // 8. FRIENDS & SOCIAL LISTENING STORE (Scoped)
  // -------------------------------------------------------------
  List<Friend> get friends => List.unmodifiable(_friends);
  List<Friend> get friendsListening =>
      _friends.where((f) => f.isListening).toList();

  Future<void> _loadFriends() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('friends'));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _friends.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _friends.add(Friend.fromJson(item));
          }
        }
      }

      if (_friends.isEmpty) {
        // Start with clean empty friends list or offline sample contact
        await _flushFriends();
      }
    } catch (_) {}
  }

  Future<void> _flushFriends() async {
    try {
      final list = _friends.map((f) => f.toJson()).toList();
      await StorageEngine.setItem(_scopedKey('friends'), jsonEncode(list));
    } catch (_) {}
  }

  Future<Friend> addFriend(String email, {String? name}) async {
    final cleanEmail = email.trim();
    String displayName = name?.trim() ?? '';
    if (displayName.isEmpty) {
      displayName = cleanEmail.split('@').first;
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      } else {
        displayName = 'Friend';
      }
    }

    final newFriend = Friend(
      id: 'f_${DateTime.now().millisecondsSinceEpoch}',
      name: displayName,
      email: cleanEmail,
      avatarInitials: displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : 'F',
      currentSongTitle: 'Kahani Suno 2.0',
      currentSongArtist: 'Kaifi Khalil',
      currentSongId: '3',
      currentSongCover:
          'https://c.saavncdn.com/editorial/BestOfIndieHindi_20230324103126_500x500.jpg',
      isOnline: true,
      isListening: true,
    );

    _friends.removeWhere(
      (f) => f.email.toLowerCase() == cleanEmail.toLowerCase(),
    );
    _friends.insert(0, newFriend);

    addNotification(
      title: 'New Friend Added',
      message: '$displayName ($cleanEmail) is now connected with you.',
      type: 'friend',
    );

    notifyListeners();
    await _flushFriends();
    return newFriend;
  }

  Future<void> removeFriend(String friendId) async {
    _friends.removeWhere((f) => f.id == friendId);
    notifyListeners();
    await _flushFriends();
  }

  // -------------------------------------------------------------
  // 9. SHARED PLAYLISTS
  // -------------------------------------------------------------
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

    notifyListeners();
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

        notifyListeners();
        await _flushPlaylists();
      }
    }
  }

  // -------------------------------------------------------------
  // 10. NOTIFICATIONS STORE (Scoped)
  // -------------------------------------------------------------
  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);

  Future<void> _loadNotifications() async {
    try {
      final raw = await StorageEngine.getItem(_scopedKey('notifications'));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _notifications.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _notifications.add(item);
          }
        }
      }

      if (_notifications.isEmpty) {
        _notifications.addAll([
          {
            'id': 'n_1',
            'title': 'Friend Activity',
            'message':
                'Unknown is currently listening to "You" by Armaan Malik.',
            'type': 'friend',
            'timestamp': DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
            'isRead': false,
          },
          {
            'id': 'n_2',
            'title': 'Shared Blend Ready',
            'message':
                'Invite friends by email to create collaborative playlists and listen together!',
            'type': 'invite',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'isRead': false,
          },
          {
            'id': 'n_3',
            'title': 'High Fidelity Audio',
            'message': 'Lossless 320kbps streaming & offline caching active.',
            'type': 'system',
            'timestamp': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'isRead': true,
          },
        ]);
        await _flushNotifications();
      }
    } catch (_) {}
  }

  Future<void> _flushNotifications() async {
    try {
      await StorageEngine.setItem(
        _scopedKey('notifications'),
        jsonEncode(_notifications),
      );
    } catch (_) {}
  }

  Future<void> addNotification({
    required String title,
    required String message,
    String type = 'system',
  }) async {
    final notif = {
      'id': 'n_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    _notifications.insert(0, notif);
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    notifyListeners();
    await _flushNotifications();
  }

  Future<void> markAllNotificationsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i]['isRead'] = true;
    }
    notifyListeners();
    await _flushNotifications();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    notifyListeners();
    await _flushNotifications();
  }

  // -------------------------------------------------------------
  // 11. DATA EXPORT, LOCAL WIPE & ACCOUNT DATA DELETION
  // -------------------------------------------------------------
  Future<String> exportAllDataJson() async {
    final export = {
      'app': 'Jumbo Music',
      'exportedAt': DateTime.now().toIso8601String(),
      'scope': _currentScope,
      'profile': {
        'name': _userName,
        'email': _userEmail,
        'bio': _userBio,
        'userId': _userId,
      },
      'friends': _friends.map((f) => f.toJson()).toList(),
      'favorites': _favoriteSongsMap.values.map((s) => s.toJson()).toList(),
      'customPlaylists': _customPlaylists.map((p) => p.toJson()).toList(),
      'downloads': _downloadsMap.values.toList(),
      'history': _historyList,
      'searchHistory': _searchHistory,
      'settings': _settings,
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Wipe data for the currently active scope
  Future<void> clearAllUserData() async {
    _clearMemoryStores();
    await Future.wait([
      StorageEngine.removeItem(_scopedKey('favorites')),
      StorageEngine.removeItem(_scopedKey('playlists')),
      StorageEngine.removeItem(_scopedKey('downloads')),
      StorageEngine.removeItem(_scopedKey('history')),
      StorageEngine.removeItem(_scopedKey('search_history')),
      StorageEngine.removeItem(_scopedKey('friends')),
      StorageEngine.removeItem(_scopedKey('notifications')),
      StorageEngine.removeItem(_scopedKey('profile')),
    ]);
    notifyListeners();
  }

  /// Delete local stored data for a specific user UID (called during complete account deletion)
  Future<void> deleteScopedLocalData(String uid) async {
    final targetScope = uid.startsWith('user_') ? uid : 'user_$uid';
    await Future.wait([
      StorageEngine.removeItem('jumbo_${targetScope}_favorites'),
      StorageEngine.removeItem('jumbo_${targetScope}_playlists'),
      StorageEngine.removeItem('jumbo_${targetScope}_downloads'),
      StorageEngine.removeItem('jumbo_${targetScope}_history'),
      StorageEngine.removeItem('jumbo_${targetScope}_search_history'),
      StorageEngine.removeItem('jumbo_${targetScope}_friends'),
      StorageEngine.removeItem('jumbo_${targetScope}_notifications'),
      StorageEngine.removeItem('jumbo_${targetScope}_profile'),
      StorageEngine.removeItem('jumbo_${targetScope}_settings'),
    ]);
    if (_currentScope == targetScope) {
      _clearMemoryStores();
      notifyListeners();
    }
  }
}
