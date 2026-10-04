part of '../database_service.dart';

// -------------------------------------------------------------
// 11. DATA EXPORT, LOCAL WIPE & ACCOUNT DATA DELETION
// -------------------------------------------------------------
extension DatabaseServiceExport on DatabaseService {
  Future<String> exportAllDataJson() async {
    final validFriends = _friends
        .where(
          (f) =>
              f.id != 'friend_unknown' &&
              f.id != 'friend_aarav' &&
              f.email != 'friend@email.com' &&
              f.name != 'Unknown',
        )
        .toList();

    final export = {
      'app': 'Jumbo Music',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'scope': _currentScope,
      'profile': {
        'name': _userName,
        'email': _userEmail,
        'bio': _userBio,
        'userId': userId,
        'isLoggedIn': _isLoggedIn,
        'isGuest': _isGuest,
      },
      'summary': {
        'totalFavorites': _favoriteSongsMap.length,
        'totalPlaylists': _customPlaylists.length,
        'totalDownloads': _downloadsMap.length,
        'totalHistory': _historyList.length,
        'totalFriends': validFriends.length,
      },
      'favorites': _favoriteSongsMap.values.map((s) => s.toJson()).toList(),
      'customPlaylists': _customPlaylists.map((p) => p.toJson()).toList(),
      'downloads': _downloadsMap.values.toList(),
      'history': _historyList,
      'searchHistory': _searchHistory,
      'friends': validFriends.map((f) => f.toJson()).toList(),
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
    notify();
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
      notify();
    }
  }
}
