import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'database_service.dart';

class FirestoreSyncService {
  static final FirestoreSyncService instance = FirestoreSyncService._internal();
  FirestoreSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _favoritesSubscription;
  StreamSubscription? _playlistsSubscription;
  StreamSubscription? _historySubscription;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Sync user profile to Firestore
  Future<void> syncUserProfile(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'Music Lover',
        'photoURL': user.photoURL ?? '',
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore syncUserProfile note: $e');
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
      debugPrint('Firestore syncAllUserData note: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Push a single favorite change to Cloud Firestore
  Future<void> pushFavoriteToCloud(Song song, bool isFavorited) async {
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
      debugPrint('Firestore pushFavoriteToCloud note: $e');
    }
  }

  /// Push custom playlist to Cloud Firestore
  Future<void> pushPlaylistToCloud(Playlist playlist) async {
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
      debugPrint('Firestore pushPlaylistToCloud note: $e');
    }
  }

  /// Delete playlist from Cloud Firestore
  Future<void> deletePlaylistFromCloud(String playlistId) async {
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
      debugPrint('Firestore deletePlaylistFromCloud note: $e');
    }
  }

  /// Push history record to Cloud Firestore
  Future<void> pushHistoryToCloud(Song song) async {
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
      debugPrint('Firestore pushHistoryToCloud note: $e');
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
      for (final doc in snap.docs) {
        final data = doc.data();
        final song = Song.fromJson(data);
        if (!db.isFavorite(song.id)) {
          await db.toggleFavorite(song, syncToCloud: false);
        }
      }
    } catch (e) {
      debugPrint('Error pulling favorites from cloud: $e');
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
      for (final doc in snap.docs) {
        final data = doc.data();
        final playlist = Playlist.fromJson(data);
        if (!db.customPlaylists.any((p) => p.id == playlist.id)) {
          await db.addCustomPlaylist(playlist, syncToCloud: false);
        }
      }
    } catch (e) {
      debugPrint('Error pulling playlists from cloud: $e');
    }
  }

  Future<void> _pullHistoryFromCloud(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('playedAt', descending: true)
          .limit(30)
          .get();

      final db = DatabaseService.instance;
      for (final doc in snap.docs.reversed) {
        final data = doc.data();
        final song = Song.fromJson(data);
        await db.addToHistory(song, syncToCloud: false);
      }
    } catch (e) {
      debugPrint('Error pulling history from cloud: $e');
    }
  }

  void _startRealtimeListeners(String uid) {
    cancelRealtimeListeners();

    // Listen to cloud favorites changes
    _favoritesSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      final db = DatabaseService.instance;
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final song = Song.fromJson(change.doc.data()!);
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
    }, onError: (e) => debugPrint('Favorites cloud listener error: $e'));
  }

  void cancelRealtimeListeners() {
    _favoritesSubscription?.cancel();
    _playlistsSubscription?.cancel();
    _historySubscription?.cancel();
    _favoritesSubscription = null;
    _playlistsSubscription = null;
    _historySubscription = null;
  }
}
