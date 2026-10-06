import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import 'database_service.dart';
import 'crash_reporting_service.dart';
import 'presence_service.dart';

/// Service managing asynchronous friend requests stored in Firestore `friend_requests`.
class FriendRequestService extends ChangeNotifier {
  static FriendRequestService _instance = FriendRequestService._internal();
  factory FriendRequestService() => _instance;
  static FriendRequestService get instance => _instance;

  FriendRequestService._internal();

  @visibleForTesting
  static set instance(FriendRequestService testInstance) {
    _instance = testInstance;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = FriendRequestService._internal();
  }

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

  String? get currentUid {
    try {
      return _auth?.currentUser?.uid ??
          (DatabaseService.instance.isLoggedIn
              ? DatabaseService.instance.userId
              : null);
    } catch (_) {
      return null;
    }
  }

  String get currentUserName {
    try {
      final authName = _auth?.currentUser?.displayName;
      if (authName != null && authName.isNotEmpty) return authName;
      return DatabaseService.instance.userName;
    } catch (_) {
      return 'Friend';
    }
  }

  String get currentUserEmail {
    try {
      final authEmail = _auth?.currentUser?.email;
      if (authEmail != null && authEmail.isNotEmpty) return authEmail;
      return DatabaseService.instance.userEmail;
    } catch (_) {
      return '';
    }
  }

  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingAcceptedSub;

  final List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> get incomingRequests =>
      List.unmodifiable(_incomingRequests);

  // Testing hooks
  @visibleForTesting
  Future<void> Function(String email)? mockSendRequest;
  @visibleForTesting
  Future<void> Function(FriendRequest request)? mockAcceptRequest;
  @visibleForTesting
  Future<void> Function(FriendRequest request)? mockDeclineRequest;
  @visibleForTesting
  Future<Friend?> Function(String email)? mockSearchUser;

  @visibleForTesting
  void setMockIncomingRequests(List<FriendRequest> requests) {
    _incomingRequests.clear();
    _incomingRequests.addAll(requests);
    notifyListeners();
  }

  /// Start listening to incoming pending requests and outgoing accepted requests for [uid].
  void startListening(String uid) {
    stopListening();
    final fs = _firestore;
    if (fs == null) return;

    try {
      // 1. Listen for pending incoming requests where toUid == uid
      _incomingSub = fs
          .collection('friend_requests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen(
            (snapshot) {
              _incomingRequests.clear();
              for (final doc in snapshot.docs) {
                _incomingRequests.add(
                  FriendRequest.fromJson(doc.data(), id: doc.id),
                );
              }
              notifyListeners();
            },
            onError: (e) {
              CrashReportingService.swallow(
                e,
                'friend_request_service.dart:incomingSub',
              );
            },
          );

      // 2. Listen for outgoing requests that were accepted by recipient
      _outgoingAcceptedSub = fs
          .collection('friend_requests')
          .where('fromUid', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots()
          .listen(
            (snapshot) {
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final toUid = data['toUid'] as String?;
                final toName = data['toName'] as String?;
                final toEmail = data['toEmail'] as String?;

                if (toUid != null && toUid.isNotEmpty) {
                  final newFriend = Friend(
                    id: toUid,
                    name: toName != null && toName.isNotEmpty
                        ? toName
                        : 'Friend',
                    email: toEmail ?? '',
                    avatarInitials: (toName != null && toName.isNotEmpty)
                        ? toName[0].toUpperCase()
                        : 'F',
                  );
                  DatabaseService.instance.saveFriendLocally(newFriend);
                  _syncFriendToCloud(uid, newFriend);
                }
              }
            },
            onError: (e) {
              CrashReportingService.swallow(
                e,
                'friend_request_service.dart:outgoingSub',
              );
            },
          );
    } catch (e) {
      CrashReportingService.swallow(e, 'friend_request_service.dart:init');
    }
  }

  void stopListening() {
    _incomingSub?.cancel();
    _incomingSub = null;
    _outgoingAcceptedSub?.cancel();
    _outgoingAcceptedSub = null;
    _incomingRequests.clear();
    notifyListeners();
  }

  /// Sends a friend request to [email].
  Future<void> sendFriendRequest(String email) async {
    if (mockSendRequest != null) {
      await mockSendRequest!(email);
      return;
    }

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }

    final uid = currentUid;
    if (uid == null ||
        !DatabaseService.instance.isLoggedIn ||
        DatabaseService.instance.isGuest) {
      throw Exception(
        'You must be signed in with an account to send friend requests.',
      );
    }

    final myEmail = currentUserEmail.trim().toLowerCase();
    if (myEmail.isNotEmpty && cleanEmail == myEmail) {
      throw Exception('You cannot send a friend request to yourself.');
    }

    // Search for recipient
    final recipient = mockSearchUser != null
        ? await mockSearchUser!(cleanEmail)
        : await PresenceService.instance.searchUserByEmail(cleanEmail);

    if (recipient == null) {
      throw Exception(
        'No registered user found with email "$cleanEmail". Ensure your friend has signed in to Jumbo Music.',
      );
    }

    if (recipient.id == uid) {
      throw Exception('You cannot send a friend request to yourself.');
    }

    // Check if already friends
    final alreadyFriend = DatabaseService.instance.friends.any(
      (f) => f.id == recipient.id || f.email.toLowerCase() == cleanEmail,
    );
    if (alreadyFriend) {
      throw Exception('${recipient.name} is already in your friends list.');
    }

    final fs = _firestore;
    if (fs == null) {
      throw Exception('Database service unavailable.');
    }

    // Check for existing pending request
    final existing = await fs
        .collection('friend_requests')
        .where('fromUid', isEqualTo: uid)
        .where('toUid', isEqualTo: recipient.id)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
        'A friend request to ${recipient.name} is already pending.',
      );
    }

    // Create pending request
    await fs.collection('friend_requests').add({
      'fromUid': uid,
      'toUid': recipient.id,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'fromName': currentUserName,
      'fromEmail': currentUserEmail,
      'toName': recipient.name,
      'toEmail': recipient.email,
    });
  }

  /// Accept incoming friend request as recipient.
  Future<void> acceptFriendRequest(FriendRequest request) async {
    if (mockAcceptRequest != null) {
      await mockAcceptRequest!(request);
      return;
    }

    final uid = currentUid;
    final fs = _firestore;
    if (uid == null || fs == null) return;

    // 1. Update friend request status in Firestore
    await fs.collection('friend_requests').doc(request.id).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Add sender as friend locally
    final newFriend = Friend(
      id: request.fromUid,
      name: request.fromName.isNotEmpty ? request.fromName : 'Friend',
      email: request.fromEmail,
      avatarInitials: request.fromInitials,
    );
    await DatabaseService.instance.saveFriendLocally(newFriend);

    // 3. Save to user's friends collection in Firestore
    await _syncFriendToCloud(uid, newFriend);

    // 4. Remove from local pending list
    _incomingRequests.removeWhere((r) => r.id == request.id);
    notifyListeners();
  }

  /// Decline incoming friend request as recipient.
  Future<void> declineFriendRequest(FriendRequest request) async {
    if (mockDeclineRequest != null) {
      await mockDeclineRequest!(request);
      return;
    }

    final fs = _firestore;
    if (fs == null) return;

    await fs.collection('friend_requests').doc(request.id).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _incomingRequests.removeWhere((r) => r.id == request.id);
    notifyListeners();
  }

  Future<void> _syncFriendToCloud(String uid, Friend friend) async {
    final fs = _firestore;
    if (fs == null) return;
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
      CrashReportingService.swallow(e, 'friend_request_service.dart:syncCloud');
    }
  }
}
