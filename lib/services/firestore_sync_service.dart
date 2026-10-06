import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'database_service.dart';
import 'crash_reporting_service.dart';

class FirestoreSyncService {
  static final FirestoreSyncService instance = FirestoreSyncService._internal();
  FirestoreSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _favoritesSubscription;
  StreamSubscription? _playlistsSubscription;
  StreamSubscription? _historySubscription;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Flag to prevent local-to-cloud and cloud-to-local sync loops
  bool _isRemoteSyncing = false;
  bool get isRemoteSyncing => _isRemoteSyncing;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Sync user profile to Firestore without overwriting createdAt if already set
  Future<void> syncUserProfile(User user, {String? customBio}) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? DatabaseService.instance.userName,
        'photoURL': user.photoURL ?? DatabaseService.instance.userAvatarUrl,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (customBio != null && customBio.isNotEmpty) {
        data['bio'] = customBio;
      } else if (!docSnap.exists) {
        data['bio'] = 'Music Lover • Jumbo Pro';
      }

      if (!docSnap.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:syncUserProfile');
    }
  }

  /// Update profile metadata in Cloud Firestore
  Future<void> updateProfileInCloud({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (name != null) data['displayName'] = name;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['photoURL'] = avatarUrl;

      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:updateProfileInCloud');
    }
  }

  /// Initial full sync when user logs in
  Future<void> syncAllUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isSyncing = true;
    try {
      await syncUserProfile(user);
      await _pullFavoritesFromCloud(user.uid);
      await _pullPlaylistsFromCloud(user.uid);
      await _pullHistoryFromCloud(user.uid);
      _startRealtimeListeners(user.uid);
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:syncAllUserData');
    } finally {
      _isSyncing = false;
    }
  }

  /// Push a single favorite change to Cloud Firestore
  Future<void> pushFavoriteToCloud(Song song, bool isFavorited) async {
    if (_isRemoteSyncing) return;
    final uid = currentUid;
    if (uid == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(song.id);

      if (isFavorited) {
        final data = song.toJson();
        data['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.set(data, SetOptions(merge: true));
      } else {
        await docRef.delete();
      }
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:pushFavoriteToCloud');
    }
  }

  /// Push custom playlist to Cloud Firestore
  Future<void> pushPlaylistToCloud(Playlist playlist) async {
    if (_isRemoteSyncing) return;
    final uid = currentUid;
    if (uid == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('playlists')
          .doc(playlist.id);

      final data = playlist.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:pushPlaylistToCloud');
    }
  }

  /// Delete playlist from Cloud Firestore
  Future<void> deletePlaylistFromCloud(String playlistId) async {
    if (_isRemoteSyncing) return;
    final uid = currentUid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('playlists')
          .doc(playlistId)
          .delete();
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:deletePlaylistFromCloud');
    }
  }

  /// Push history record to Cloud Firestore
  Future<void> pushHistoryToCloud(Song song) async {
    if (_isRemoteSyncing) return;
    final uid = currentUid;
    if (uid == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc(song.id);

      final data = song.toJson();
      data['playedAt'] = FieldValue.serverTimestamp();
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:pushHistoryToCloud');
    }
  }

  Future<void> _pullFavoritesFromCloud(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();

      final db = DatabaseService.instance;
      _isRemoteSyncing = true;
      try {
        for (final doc in snap.docs) {
          final data = doc.data();
          final song = Song.fromJson(data);
          if (!db.isFavorite(song.id)) {
            await db.toggleFavorite(song, syncToCloud: false);
          }
        }
      } finally {
        _isRemoteSyncing = false;
      }
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:_pullFavoritesFromCloud');
    }
  }

  Future<void> _pullPlaylistsFromCloud(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('playlists')
          .get();

      final db = DatabaseService.instance;
      _isRemoteSyncing = true;
      try {
        for (final doc in snap.docs) {
          final data = doc.data();
          final playlist = Playlist.fromJson(data);
          if (!db.customPlaylists.any((p) => p.id == playlist.id)) {
            await db.addCustomPlaylist(playlist, syncToCloud: false);
          }
        }
      } finally {
        _isRemoteSyncing = false;
      }
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:_pullPlaylistsFromCloud');
    }
  }

  Future<void> _pullHistoryFromCloud(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('playedAt', descending: true)
          .limit(50)
          .get();

      final db = DatabaseService.instance;
      _isRemoteSyncing = true;
      try {
        for (final doc in snap.docs.reversed) {
          final data = doc.data();
          final song = Song.fromJson(data);
          await db.addToHistory(song, syncToCloud: false);
        }
      } finally {
        _isRemoteSyncing = false;
      }
    } catch (e) {
      CrashReportingService.swallow(e, 'firestore_sync_service.dart:_pullHistoryFromCloud');
    }
  }

  void _startRealtimeListeners(String uid) {
    cancelRealtimeListeners();

    // 1. Listen to cloud favorites changes
    _favoritesSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
          if (_isRemoteSyncing) return;
          final db = DatabaseService.instance;
          _isRemoteSyncing = true;
          try {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data == null) continue;
                final song = Song.fromJson(data);
                if (!db.isFavorite(song.id)) {
                  db.toggleFavorite(song, syncToCloud: false);
                }
              } else if (change.type == DocumentChangeType.removed) {
                final id = change.doc.id;
                if (db.isFavorite(id)) {
                  final song = db.favoriteSongs.firstWhere(
                    (s) => s.id == id,
                    orElse: () => Song(
                      id: id,
                      title: '',
                      artist: '',
                      audioUrl: '',
                      coverUrl: '',
                      duration: Duration.zero,
                    ),
                  );
                  db.toggleFavorite(song, syncToCloud: false);
                }
              }
            }
          } finally {
            _isRemoteSyncing = false;
          }
        }, onError: (e) => CrashReportingService.swallow(e, 'firestore_sync_service.dart:favorites_listener'));

    // 2. Listen to cloud playlists changes
    _playlistsSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .snapshots()
        .listen((snapshot) {
          if (_isRemoteSyncing) return;
          final db = DatabaseService.instance;
          _isRemoteSyncing = true;
          try {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final data = change.doc.data();
                if (data == null) continue;
                final playlist = Playlist.fromJson(data);
                db.addCustomPlaylist(playlist, syncToCloud: false);
              } else if (change.type == DocumentChangeType.removed) {
                db.deletePlaylist(change.doc.id, syncToCloud: false);
              }
            }
          } finally {
            _isRemoteSyncing = false;
          }
        }, onError: (e) => CrashReportingService.swallow(e, 'firestore_sync_service.dart:playlists_listener'));

    // 3. Listen to cloud history changes
    _historySubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('playedAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snapshot) {
          if (_isRemoteSyncing) return;
          final db = DatabaseService.instance;
          _isRemoteSyncing = true;
          try {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data == null) continue;
                final song = Song.fromJson(data);
                db.addToHistory(song, syncToCloud: false);
              }
            }
          } finally {
            _isRemoteSyncing = false;
          }
        }, onError: (e) => CrashReportingService.swallow(e, 'firestore_sync_service.dart:history_listener'));
  }

  void cancelRealtimeListeners() {
    _favoritesSubscription?.cancel();
    _playlistsSubscription?.cancel();
    _historySubscription?.cancel();
    _favoritesSubscription = null;
    _playlistsSubscription = null;
    _historySubscription = null;
  }

  /// Delete all cloud user data for GDPR / Account Deletion
  Future<void> deleteUserDataFromCloud(String uid) async {
    try {
      final fs = FirebaseFirestore.instance;
      await fs.collection('presence').doc(uid).delete();
      await fs.collection('public_profiles').doc(uid).delete();
    } catch (error) {
      CrashReportingService.swallow(error, 'firestore_sync_service.dart:372');
    }
    cancelRealtimeListeners();
    try {
      final userDocRef = _firestore.collection('users').doc(uid);

      // 1. Delete favorites
      final favs = await userDocRef.collection('favorites').get();
      for (final doc in favs.docs) {
        await doc.reference.delete();
      }

      // 2. Delete playlists
      final pls = await userDocRef.collection('playlists').get();
      for (final doc in pls.docs) {
        await doc.reference.delete();
      }

      // 3. Delete history
      final hist = await userDocRef.collection('history').get();
      for (final doc in hist.docs) {
        await doc.reference.delete();
      }

      // 4. Delete user doc
      await userDocRef.delete();
    } catch (e) {
      debugPrint('Firestore deleteUserDataFromCloud error: $e');
      rethrow;
    }
  }
}
