part of '../database_service.dart';

// -------------------------------------------------------------
// 4. LISTENING HISTORY, 5. SEARCH HISTORY, 8. FRIENDS, 10. NOTIFICATIONS
// -------------------------------------------------------------
extension DatabaseServiceHistoryAndSocial on DatabaseService {
  // 4. History
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

    notify();
    await _flushHistory();

    if (syncToCloud && _isLoggedIn && _currentScope.startsWith('user_')) {
      FirestoreSyncService.instance.pushHistoryToCloud(song);
    }
  }

  Future<void> addToHistory(Song song, {bool syncToCloud = true}) =>
      addHistory(song, syncToCloud: syncToCloud);

  Future<void> clearHistory() async {
    _historyList.clear();
    notify();
    await _flushHistory();
  }

  // 5. Search History
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

    notify();
    await _flushSearchHistory();
  }

  Future<void> removeSearchQuery(String query) async {
    _searchHistory.removeWhere(
      (item) => item.toLowerCase() == query.trim().toLowerCase(),
    );
    notify();
    await _flushSearchHistory();
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notify();
    await _flushSearchHistory();
  }

  // 8. Friends
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

  Future<void> saveFriendLocally(Friend friend) async {
    _friends.removeWhere((f) => f.id == friend.id || f.email.toLowerCase() == friend.email.toLowerCase());
    _friends.insert(0, friend);
    addNotification(
      title: 'New Friend Connected',
      message: '${friend.name} (${friend.email}) is now in your friends list.',
      type: 'friend',
    );
    notify();
    await _flushFriends();
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
      id: 'f_${cleanEmail.hashCode.abs()}',
      name: displayName,
      email: cleanEmail,
      avatarInitials: displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : 'F',
      currentSongTitle: '',
      currentSongArtist: '',
      isOnline: true,
      isListening: false,
    );

    await saveFriendLocally(newFriend);
    return newFriend;
  }

  Future<void> removeFriend(String friendId) async {
    _friends.removeWhere((f) => f.id == friendId);
    notify();
    await _flushFriends();
  }

  // 10. Notifications
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
    notify();
    await _flushNotifications();
  }

  Future<void> markAllNotificationsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i]['isRead'] = true;
    }
    notify();
    await _flushNotifications();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    notify();
    await _flushNotifications();
  }
}
