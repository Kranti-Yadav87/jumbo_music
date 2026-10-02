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
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Helper to convert Firebase Auth exceptions to user-friendly messages
  static String formatAuthError(Object error) {
    final msg = error.toString();
    if (msg.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in instead.';
    } else if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (msg.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters with letters and numbers.';
    } else if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (msg.contains('too-many-requests')) {
      return 'Too many unsuccessful attempts. Please try again in a few minutes.';
    } else if (msg.contains('network-request-failed')) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (msg.contains('user-disabled')) {
      return 'This user account has been deactivated.';
    } else if (msg.contains('requires-recent-login')) {
      return 'This security action requires recent login. Please re-authenticate.';
    }
    return msg.contains(']') ? msg.split(']').last.trim() : msg;
  }

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
        final GoogleSignInAccount account = await GoogleSignIn.instance
            .authenticate(scopeHint: const ['email', 'profile']);

        final idToken = account.authentication.idToken;
        final authClient = await account.authorizationClient
            .authorizationForScopes(const ['email', 'profile']);
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
      final user = credential.user;
      if (user != null) {
        if (name.isNotEmpty) {
          await user.updateDisplayName(name.trim());
        }
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('sendEmailVerification note: $e');
        }
      }
      await _syncWithDatabase(user, customName: name);
      return credential;
    } catch (e) {
      debugPrint('Error creating account: $e');
      rethrow;
    }
  }

  /// Resend verification email to current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload user profile & check verification status
  Future<bool> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return _auth.currentUser?.emailVerified ?? false;
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
    return false;
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

  /// Update user display name and bio across Firebase Auth, Firestore, and Local DB
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
      }
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        await user.updatePhotoURL(avatarUrl.trim());
      }
      // Update in Cloud Firestore
      await FirestoreSyncService.instance.updateProfileInCloud(
        name: name,
        bio: bio,
        avatarUrl: avatarUrl,
      );
    }
    // Update locally
    await DatabaseService.instance.updateProfile(
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
    );
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

  /// Complete Account Deletion (GDPR & Security Compliant)
  Future<void> deleteAccount({AuthCredential? reauthCredential}) async {
    final user = _auth.currentUser;
    if (user == null) {
      await DatabaseService.instance.clearAllUserData();
      await DatabaseService.instance.logout();
      return;
    }

    final uid = user.uid;

    try {
      if (reauthCredential != null) {
        await user.reauthenticateWithCredential(reauthCredential);
      }

      // 1. Delete Firestore Cloud Data
      try {
        await FirestoreSyncService.instance.deleteUserDataFromCloud(uid);
      } catch (e) {
        debugPrint('Cloud data deletion note: $e');
      }

      // 2. Delete Local Scoped Data
      await DatabaseService.instance.deleteScopedLocalData(uid);

      // 3. Delete Firebase Auth User
      await user.delete();

      // 4. Sign out
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
      await DatabaseService.instance.logout();
    } catch (e) {
      debugPrint('Error during account deletion: $e');
      rethrow;
    }
  }

  Future<void> _syncWithDatabase(User? user, {String? customName}) async {
    if (user == null) return;
    final name =
        customName ??
        user.displayName ??
        user.email?.split('@').first ??
        'User';
    final email = user.email ?? 'user@jumbomusic.app';
    final photoUrl = user.photoURL ?? '';
    final userId = 'JM-${(user.uid.hashCode.abs() % 90000 + 10000)}';

    final db = DatabaseService.instance;
    await db.login(email: email, name: name, userId: userId, uid: user.uid);
    if (photoUrl.isNotEmpty) {
      await db.updateProfile(avatarUrl: photoUrl);
    }

    FirestoreSyncService.instance.syncAllUserData();
  }
}
