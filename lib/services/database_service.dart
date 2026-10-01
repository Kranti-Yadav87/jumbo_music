import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/friend.dart';
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
  final List<String> _searchHistory = [];
  final List<Friend> _friends = [];
  final List<Map<String, dynamic>> _notifications = [];
  
  // User Profile & Authentication
  bool _isLoggedIn = false;
  String _userId = '';
  String _userName = 'User';
  String _userEmail = 'user@jumbomusic.app';
  String _userAvatarUrl = '';
  String _userBio = 'Music Lover • Jumbo Pro';

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
  static const String _keySearchHistory = 'jumbo_db_search_history';
  static const String _keySettings = 'jumbo_db_settings';
  static const String _keyProfile = 'jumbo_db_profile';
  static const String _keyFriends = 'jumbo_db_friends';
  static const String _keyNotifications = 'jumbo_db_notifications';

  /// Initialize database and load all stores into memory
  Future<void> init() async {
    if (_isInitialized) return;

    try {
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
  // 5. SEARCH HISTORY STORE
  // -------------------------------------------------------------
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  Future<void> _loadSearchHistory() async {
    try {
      final raw = await StorageEngine.getItem(_keySearchHistory);
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
      await StorageEngine.setItem(_keySearchHistory, jsonEncode(_searchHistory));
    } catch (_) {}
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Respect Incognito Mode
    if (getSetting('incognitoMode', false) == true) return;

    _searchHistory.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    _searchHistory.insert(0, trimmed);

    if (_searchHistory.length > 25) {
      _searchHistory.removeRange(25, _searchHistory.length);
    }

    notifyListeners();
    await _flushSearchHistory();
  }

  Future<void> removeSearchQuery(String query) async {
    _searchHistory.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());
    notifyListeners();
    await _flushSearchHistory();
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();
    await _flushSearchHistory();
  }

  // -------------------------------------------------------------
  // 6. SETTINGS STORE
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

  Future<void> saveSetting(String key, dynamic value) => updateSetting(key, value);

  // -------------------------------------------------------------
  // 7. USER PROFILE & AUTHENTICATION STORE
  // -------------------------------------------------------------
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId.isNotEmpty ? _userId : 'JM-${(_userEmail.hashCode.abs() % 90000 + 10000)}';
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
      final raw = await StorageEngine.getItem(_keyProfile);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _isLoggedIn = data['isLoggedIn'] as bool? ?? false;
        _userId = data['userId'] as String? ?? '';
        _userName = data['name'] as String? ?? 'User';
        _userEmail = data['email'] as String? ?? 'user@jumbomusic.app';
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
      await StorageEngine.setItem(_keyProfile, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> login({
    required String email,
    required String name,
    String? password,
    String? userId,
  }) async {
    _isLoggedIn = true;
    _userEmail = email.trim();
    _userName = name.trim().isNotEmpty ? name.trim() : email.split('@').first;
    _userId = userId ?? 'JM-${(_userEmail.hashCode.abs() % 90000 + 10000)}';
    notifyListeners();
    await _flushProfile();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = 'User';
    _userEmail = 'user@jumbomusic.app';
    _userId = '';
    notifyListeners();
    await _flushProfile();
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
  // 8. FRIENDS & SOCIAL LISTENING STORE
  // -------------------------------------------------------------
  List<Friend> get friends => List.unmodifiable(_friends);
  List<Friend> get friendsListening => _friends.where((f) => f.isListening).toList();

  Future<void> _loadFriends() async {
    try {
      final raw = await StorageEngine.getItem(_keyFriends);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _friends.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _friends.add(Friend.fromJson(item));
          }
        }
      }
      
      // Default seeded friend matching Screenshot 2 if empty
      if (_friends.isEmpty) {
        _friends.addAll([
          Friend(
            id: 'friend_unknown',
            name: 'Unknown',
            email: 'friend@email.com',
            avatarInitials: 'U',
            currentSongTitle: 'You',
            currentSongArtist: 'Armaan Malik',
            currentSongId: '1',
            currentSongCover: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
            isOnline: true,
            isListening: true,
          ),
          Friend(
            id: 'friend_aarav',
            name: 'Aarav Sharma',
            email: 'aarav.sharma@gmail.com',
            avatarInitials: 'AS',
            currentSongTitle: 'Tumhein Apna Banane Ki',
            currentSongArtist: 'Kumar Sanu',
            currentSongId: '2',
            currentSongCover: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
            isOnline: true,
            isListening: true,
          ),
        ]);
        await _flushFriends();
      }
    } catch (_) {}
  }

  Future<void> _flushFriends() async {
    try {
      final list = _friends.map((f) => f.toJson()).toList();
      await StorageEngine.setItem(_keyFriends, jsonEncode(list));
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
      avatarInitials: displayName.isNotEmpty ? displayName[0].toUpperCase() : 'F',
      currentSongTitle: 'Kahani Suno 2.0',
      currentSongArtist: 'Kaifi Khalil',
      currentSongId: '3',
      currentSongCover: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&auto=format&fit=crop&q=80',
      isOnline: true,
      isListening: true,
    );

    // Remove existing if duplicate email
    _friends.removeWhere((f) => f.email.toLowerCase() == cleanEmail.toLowerCase());
    _friends.insert(0, newFriend);

    // Add a notification about new friend connection
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

  Future<void> updateFriendListening(
    String friendId, {
    required String songTitle,
    required String songArtist,
    String? songId,
    String? coverUrl,
  }) async {
    final idx = _friends.indexWhere((f) => f.id == friendId);
    if (idx != -1) {
      _friends[idx] = _friends[idx].copyWith(
        currentSongTitle: songTitle,
        currentSongArtist: songArtist,
        currentSongId: songId ?? _friends[idx].currentSongId,
        currentSongCover: coverUrl ?? _friends[idx].currentSongCover,
        isListening: true,
        isOnline: true,
      );
      notifyListeners();
      await _flushFriends();
    }
  }

  // -------------------------------------------------------------
  // 9. SHARED & COLLABORATIVE PLAYLISTS (Friend Blend)
  // -------------------------------------------------------------
  List<Playlist> get sharedPlaylists =>
      _customPlaylists.where((p) => p.isCollaborative || p.type == PlaylistType.sharedBlend).toList();

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
              : 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80'),
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
      message: 'You and ${friend.name} can now add and listen to songs together in "$playlistTitle"!',
      type: 'playlist',
    );

    notifyListeners();
    await _flushPlaylists();
    return playlist;
  }

  // -------------------------------------------------------------
  // 10. NOTIFICATIONS STORE
  // -------------------------------------------------------------
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  Future<void> _loadNotifications() async {
    try {
      final raw = await StorageEngine.getItem(_keyNotifications);
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
            'message': 'Unknown is currently listening to "You" by Armaan Malik.',
            'type': 'friend',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
            'isRead': false,
          },
          {
            'id': 'n_2',
            'title': 'Shared Blend Ready',
            'message': 'Invite friends by email to create collaborative playlists and listen together!',
            'type': 'invite',
            'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'isRead': false,
          },
          {
            'id': 'n_3',
            'title': 'High Fidelity Audio',
            'message': 'Lossless 320kbps streaming & offline caching active.',
            'type': 'system',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'isRead': true,
          },
        ]);
        await _flushNotifications();
      }
    } catch (_) {}
  }

  Future<void> _flushNotifications() async {
    try {
      await StorageEngine.setItem(_keyNotifications, jsonEncode(_notifications));
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
  // 11. GDPR DATA EXPORT & TOTAL WIPE
  // -------------------------------------------------------------
  Future<String> exportAllDataJson() async {
    final export = {
      'app': 'Jumbo Music',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': {
        'name': _userName,
        'email': _userEmail,
        'bio': _userBio,
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

  Future<void> clearAllUserData() async {
    _favoriteIds.clear();
    _favoriteSongsMap.clear();
    _customPlaylists.clear();
    _downloadsMap.clear();
    _historyList.clear();
    _searchHistory.clear();
    _friends.clear();
    _notifications.clear();
    _userName = 'User';
    _userEmail = 'user@jumbomusic.app';

    await Future.wait([
      StorageEngine.removeItem(_keyFavorites),
      StorageEngine.removeItem(_keyPlaylists),
      StorageEngine.removeItem(_keyDownloads),
      StorageEngine.removeItem(_keyHistory),
      StorageEngine.removeItem(_keySearchHistory),
      StorageEngine.removeItem(_keyFriends),
      StorageEngine.removeItem(_keyNotifications),
      StorageEngine.removeItem(_keyProfile),
    ]);

    notifyListeners();
  }
}
