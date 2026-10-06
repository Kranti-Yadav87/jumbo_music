import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import 'database_service.dart';
import 'firestore_sync_service.dart';
import 'music_player_manager.dart';
import 'crash_reporting_service.dart';

class AuthService {
  static AuthService instance = AuthService._internal();

  @visibleForTesting
  static void resetInstance() {
    instance = AuthService._internal();
  }

  AuthService({FirebaseAuth? auth}) : _customAuth = auth;
  AuthService._internal() : _customAuth = null;

  final FirebaseAuth? _customAuth;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  bool _isGoogleSignInInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Helper to convert Firebase Auth exceptions to user-friendly messages
  static String formatAuthError(Object error) {
    final msg = error.toString();
    if (msg.contains('unauthorized-domain')) {
      return 'This domain is not authorized for OAuth operations. Please verify authorized domains in Firebase Console.';
    } else if (msg.contains('reauth failed') ||
        msg.contains('requires-recent-login')) {
      return 'Re-authentication failed or session expired. Please log in again.';
    } else if (msg.contains('popup-closed-by-user') ||
        msg.contains('cancelled-popup-request') ||
        msg.contains('cancelled') ||
        msg.contains('canceled') ||
        msg.contains('user-cancelled')) {
      return 'Google Sign-In was cancelled.';
    } else if (msg.contains('10') ||
        msg.contains('12500') ||
        msg.contains('DEVELOPER_ERROR')) {
      return 'Google Play Services or OAuth SHA-1 configuration check required on device.';
    } else if (msg.contains('popup-blocked')) {
      return 'Sign-in popup was blocked by your browser. Please allow popups for this site and retry.';
    } else if (msg.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email using a different sign-in method.';
    } else if (msg.contains('email-already-in-use')) {
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
    } else if (msg.contains('network-request-failed') ||
        msg.contains('SocketException')) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (msg.contains('user-disabled')) {
      return 'This user account has been deactivated.';
    }
    return msg.contains(']') ? msg.split(']').last.trim() : msg;
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleServerClientId,
      );
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
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final userCredential = await _auth.signInWithPopup(googleProvider);
        await _syncWithDatabase(userCredential.user);
        return userCredential;
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount account = await GoogleSignIn.instance
            .authenticate(scopeHint: const ['email', 'profile']);

        final idToken = account.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw FirebaseAuthException(
            code: 'null-id-token',
            message:
                'Google Sign-In failed: No ID Token returned from identity provider.',
          );
        }

        String? accessToken;
        try {
          final authClient = await account.authorizationClient
              .authorizationForScopes(const ['email', 'profile']);
          accessToken = authClient?.accessToken;
        } catch (e) {
          debugPrint('Optional accessToken fetch note: $e');
        }

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
      await MusicPlayerManager().stopPlayback();
      FirestoreSyncService.instance.cancelRealtimeListeners();
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (error) {
          CrashReportingService.swallow(error, 'auth_service.dart:238');
        }
      }
      await DatabaseService.instance.logout();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Complete Account Deletion (GDPR & Security Compliant)
  Future<void> deleteAccount({AuthCredential? reauthCredential}) async {
    await MusicPlayerManager().stopPlayback();
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
        } catch (error) {
          CrashReportingService.swallow(error, 'auth_service.dart:280');
        }
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
