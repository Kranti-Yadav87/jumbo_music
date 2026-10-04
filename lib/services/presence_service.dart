import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../models/song.dart';
import 'database_service.dart';

/// Real-time social presence service backed by Cloud Firestore.
class PresenceService extends ChangeNotifier {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  static PresenceService get instance => _instance;

  PresenceService._internal();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  StreamSubscription? _friendsSubscription;
  final Map<String, StreamSubscription> _friendUserSubs = {};
  final Map<String, Friend> _liveFriendsMap = {};

  List<Friend> _liveFriends = [];
  List<Friend> get liveFriends =>
      _liveFriends.isNotEmpty ? _liveFriends : DatabaseService.instance.friends;

  List<Friend> get liveListeningFriends =>
      liveFriends.where((f) => f.isListening).toList();

  String? get currentUid {
    try {
      return _auth?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Initialize and bind auth state changes to presence syncing
  void init() {
    try {
      _auth?.authStateChanges().listen((user) {
        if (user != null) {
          _startListeningToFriends(user.uid);
          unawaited(_publishPublicProfile(user));
          unawaited(setOnline(true));
          _startHeartbeat();
        } else {
          _heartbeat?.cancel();
          _stopListeningToFriends();
          _liveFriendsMap.clear();
          _liveFriends = [];
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('PresenceService init note: $e');
    }
  }

  Timer? _heartbeat;

  /// Keeps `lastSeen` fresh so friends never see a stale "online" state.
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(minutes: 2), (_) async {
      final uid = currentUid;
      final fs = _firestore;
      if (uid == null || fs == null) return;
      try {
        await fs.collection('presence').doc(uid).set({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  /// Only a display name + lowercase email (for exact-match friend search)
  /// is public. Everything else stays in the private `users/{uid}` document.
  Future<void> _publishPublicProfile(User user) async {
    final fs = _firestore;
    final email = user.email?.trim().toLowerCase();
    if (fs == null || email == null || email.isEmpty) return;
    try {
      await fs.collection('public_profiles').doc(user.uid).set({
        'displayName': user.displayName ?? email.split('@').first,
        'emailLower': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('PresenceService publicProfile note: $e');
    }
  }

  /// Update the current user's live listening status in Firestore
  Future<void> updateListeningStatus({
    Song? song,
    bool isPlaying = false,
    bool isIncognito = false,
  }) async {
    final uid = currentUid;
    final fs = _firestore;
    if (uid == null || fs == null) return;

    try {
      final docRef = fs.collection('presence').doc(uid);
      if (!isPlaying || song == null || isIncognito) {
        await docRef.set({
          'isListening': false,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'isListening': true,
          'isOnline': true,
          'currentSongTitle': song.title,
          'currentSongArtist': song.artist,
          'currentSongId': song.id,
          'currentSongCover': song.coverUrl,
          'currentSongDurationSeconds': song.duration.inSeconds,
          'lastSeen': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('PresenceService updateListeningStatus note: $e');
    }
  }

  /// Update user's online/offline status
  Future<void> setOnline(bool online) async {
    final uid = currentUid;
    final fs = _firestore;
    if (uid == null || fs == null) return;

    try {
      await fs.collection('presence').doc(uid).set({
        'isOnline': online,
        if (!online) 'isListening': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('PresenceService setOnline note: $e');
    }
  }

  /// Search for a real user by email in Firestore
  Future<Friend?> searchUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final fs = _firestore;
    if (cleanEmail.isEmpty || fs == null) return null;

    try {
      final query = await fs
          .collection('public_profiles')
          .where('emailLower', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final data = doc.data();
      final friendUid = doc.id;

      final name =
          (data['displayName'] as String?) ?? cleanEmail.split('@').first;
      final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

      return Friend(
        id: friendUid,
        name: name,
        email: (data['emailLower'] as String?) ?? cleanEmail,
        avatarInitials: initials,
      );
    } catch (e) {
      debugPrint('PresenceService searchUserByEmail note: $e');
      return null;
    }
  }

  /// Add friend to Firestore cloud store & local store
  Future<Friend> addFriend(String email, {String? name}) async {
    final cleanEmail = email.trim().toLowerCase();
    Friend? realFriend = await searchUserByEmail(cleanEmail);

    final friend =
        realFriend ??
        Friend(
          id: 'u_${cleanEmail.hashCode.abs()}',
          name: name ?? cleanEmail.split('@').first,
          email: cleanEmail,
          avatarInitials: (name ?? cleanEmail).substring(0, 1).toUpperCase(),
          currentSongTitle: '',
          currentSongArtist: '',
          isOnline: true,
          isListening: false,
        );

    // Save locally
    await DatabaseService.instance.saveFriendLocally(friend);

    // If logged in, save relationship in Firestore
    final uid = currentUid;
    final fs = _firestore;
    if (uid != null && fs != null) {
      try {
        await fs
            .collection('users')
            .doc(uid)
            .collection('friends')
            .doc(friend.id)
            .set({
              'friendUid': friend.id,
              'email': friend.email,
              'name': friend.name,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('PresenceService addFriend cloud note: $e');
      }
    }

    _liveFriendsMap[friend.id] = friend;
    _liveFriends = _liveFriendsMap.values.toList();
    notifyListeners();
    return friend;
  }

  /// Remove friend from cloud and local
  Future<void> removeFriend(String friendId) async {
    await DatabaseService.instance.removeFriend(friendId);
    _liveFriendsMap.remove(friendId);
    _liveFriends = _liveFriendsMap.values.toList();

    final uid = currentUid;
    final fs = _firestore;
    if (uid != null && fs != null) {
      try {
        await fs
            .collection('users')
            .doc(uid)
            .collection('friends')
            .doc(friendId)
            .delete();
      } catch (e) {
        debugPrint('PresenceService removeFriend cloud note: $e');
      }
    }

    _friendUserSubs[friendId]?.cancel();
    _friendUserSubs.remove(friendId);
    notifyListeners();
  }

  void _startListeningToFriends(String uid) {
    _stopListeningToFriends();
    final fs = _firestore;
    if (fs == null) return;

    try {
      _friendsSubscription = fs
          .collection('users')
          .doc(uid)
          .collection('friends')
          .snapshots()
          .listen((snapshot) {
            final currentFriendIds = snapshot.docs.map((d) => d.id).toSet();

            // Clean up unsubscribed friends
            final toRemove = _friendUserSubs.keys
                .where((id) => !currentFriendIds.contains(id))
                .toList();
            for (final id in toRemove) {
              _friendUserSubs[id]?.cancel();
              _friendUserSubs.remove(id);
              _liveFriendsMap.remove(id);
            }

            // Subscribe to each friend's user document for live presence
            for (final doc in snapshot.docs) {
              final friendId = doc.id;
              final friendEmail = (doc.data()['email'] as String?) ?? '';
              final friendName = (doc.data()['name'] as String?) ?? '';

              if (!_friendUserSubs.containsKey(friendId)) {
                _friendUserSubs[friendId] = fs
                    .collection('presence')
                    .doc(friendId)
                    .snapshots()
                    .listen((userDoc) {
                      if (userDoc.exists && userDoc.data() != null) {
                        final uData = userDoc.data()!;
                        final displayName = friendName.isNotEmpty
                            ? friendName
                            : 'Friend';
                        final seen = uData['lastSeen'];
                        final fresh =
                            seen is Timestamp &&
                            DateTime.now().difference(seen.toDate()) <
                                const Duration(minutes: 5);
                        final online =
                            fresh && ((uData['isOnline'] as bool?) ?? false);
                        final f = Friend(
                          id: friendId,
                          name: displayName,
                          email: friendEmail,
                          avatarInitials: displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'F',
                          currentSongTitle:
                              (uData['currentSongTitle'] as String?) ?? '',
                          currentSongArtist:
                              (uData['currentSongArtist'] as String?) ?? '',
                          currentSongId:
                              (uData['currentSongId'] as String?) ?? '',
                          currentSongCover:
                              (uData['currentSongCover'] as String?) ?? '',
                          isOnline: online,
                          isListening:
                              online &&
                              ((uData['isListening'] as bool?) ?? false),
                        );
                        _liveFriendsMap[friendId] = f;
                      } else {
                        _liveFriendsMap[friendId] = Friend(
                          id: friendId,
                          name: friendName.isNotEmpty ? friendName : 'Friend',
                          email: friendEmail,
                          avatarInitials: friendName.isNotEmpty
                              ? friendName[0].toUpperCase()
                              : 'F',
                        );
                      }
                      _liveFriends = _liveFriendsMap.values.toList();
                      notifyListeners();
                    });
              }
            }
          });
    } catch (e) {
      debugPrint('PresenceService listenToFriends error: $e');
    }
  }

  void _stopListeningToFriends() {
    _friendsSubscription?.cancel();
    _friendsSubscription = null;
    for (final sub in _friendUserSubs.values) {
      sub.cancel();
    }
    _friendUserSubs.clear();
  }
}
