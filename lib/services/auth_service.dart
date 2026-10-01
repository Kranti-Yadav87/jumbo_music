import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';
import 'firestore_sync_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isGoogleSignInInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize();
      _isGoogleSignInInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn initialize note: $e');
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential = await _auth.signInWithPopup(googleProvider);
        await _syncWithDatabase(userCredential.user);
        return userCredential;
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
          scopeHint: const ['email', 'profile'],
        );

        final idToken = account.authentication.idToken;
        final authClient = await account.authorizationClient.authorizationForScopes(
          const ['email', 'profile'],
        );
        final accessToken = authClient?.accessToken;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        await _syncWithDatabase(userCredential.user);
        return userCredential;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _syncWithDatabase(credential.user);
      return credential;
    } catch (e) {
      debugPrint('Error signing in with Email: $e');
      rethrow;
    }
  }

  /// Register / Sign up with Email and Password
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (name.isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
      }
      await _syncWithDatabase(credential.user, customName: name);
      return credential;
    } catch (e) {
      debugPrint('Error creating account: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      FirestoreSyncService.instance.cancelRealtimeListeners();
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
      await DatabaseService.instance.logout();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> _syncWithDatabase(User? user, {String? customName}) async {
    if (user == null) return;
    final name = customName ?? user.displayName ?? user.email?.split('@').first ?? 'User';
    final email = user.email ?? 'user@jumbomusic.app';
    final photoUrl = user.photoURL ?? '';
    final userId = 'JM-${(user.uid.hashCode.abs() % 90000 + 10000)}';

    final db = DatabaseService.instance;
    await db.login(
      email: email,
      name: name,
      userId: userId,
    );
    if (photoUrl.isNotEmpty) {
      await db.updateProfile(avatarUrl: photoUrl);
    }

    // Trigger Cloud Firestore Synchronization in the background
    FirestoreSyncService.instance.syncAllUserData();
  }
}
