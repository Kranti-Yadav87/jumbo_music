import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/friend.dart';
import 'storage/storage_engine.dart';
import 'firestore_sync_service.dart';

part 'db/database_service_favorites_and_downloads.dart';
part 'db/database_service_playlists.dart';
part 'db/database_service_history_and_social.dart';
part 'db/database_service_export.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void notify() => notifyListeners();

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
  bool _isGuest = false;
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

  /// Switch the active data storage scope (Guest or Authenticated User UID)
  Future<void> switchUserScope(String? uid) async {
    final newScope = (uid != null && uid.isNotEmpty)
        ? (uid.startsWith('user_') ? uid : 'user_$uid')
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
  bool get isGuest => _isLoggedIn && _isGuest;
  String get userId => (_isLoggedIn && !_isGuest)
      ? (_userId.isNotEmpty
          ? _userId
          : 'JM-${(_userEmail.hashCode.abs() % 90000 + 10000)}')
      : '';
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
        _isGuest = data['isGuest'] as bool? ?? false;
        if (_currentScope == 'guest' && !_isGuest) _isLoggedIn = false;
        _userId = data['userId'] as String? ?? '';
        _userName =
            data['name'] as String? ??
            (_isLoggedIn ? (_isGuest ? 'Guest Explorer' : 'User') : 'Guest Explorer');
        _userEmail =
            data['email'] as String? ??
            (_isLoggedIn
                ? (_isGuest ? 'guest.listener@jumbomusic.app' : 'user@jumbomusic.app')
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
        'isGuest': _isGuest,
        'userId': _userId,
        'name': _userName,
        'email': _userEmail,
        'avatarUrl': _userAvatarUrl,
        'bio': _userBio,
      };
      await StorageEngine.setItem(_scopedKey('profile'), jsonEncode(map));
    } catch (_) {}
  }

  /// Explicitly enter guest mode
  Future<void> loginAsGuest() async {
    await switchUserScope(null);
    await clearAllUserData();
    _isGuest = true;
    _isLoggedIn = true;
    _userName = 'Guest Explorer';
    _userEmail = 'guest.listener@jumbomusic.app';
    _userId = '';
    _userAvatarUrl = '';
    _userBio = 'Music Lover • Jumbo Listener';
    await _flushProfile();
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String name,
    String? password,
    String? userId,
    String? uid,
  }) async {
    _isGuest = false;
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
    final wasGuest = _isGuest;
    _isGuest = false;
    _isLoggedIn = false;
    _userName = 'Guest Explorer';
    _userEmail = 'guest.listener@jumbomusic.app';
    _userId = '';
    _userAvatarUrl = '';
    _userBio = 'Music Lover • Jumbo Listener';

    if (wasGuest) {
      await clearAllUserData();
    }

    // Switch storage scope back to guest without clearing the previous user's files
    await switchUserScope(null);

    // Loading the guest scope may restore old values; force signed-out state.
    _isGuest = false;
    _isLoggedIn = false;
    _userName = 'Guest Explorer';
    _userEmail = 'guest.listener@jumbomusic.app';
    _userId = '';
    _userAvatarUrl = '';
    await _flushProfile();
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
}
