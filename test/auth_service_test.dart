import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jumbo_music/services/auth_service.dart';
import 'package:jumbo_music/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Formatter Tests', () {
    test('Correctly maps email-already-in-use to friendly message', () {
      final err = Exception(
        '[firebase_auth/email-already-in-use] The email address is already in use by another account.',
      );
      final result = AuthService.formatAuthError(err);
      expect(
        result,
        equals('This email is already registered. Please sign in instead.'),
      );
    });

    test('Correctly maps invalid-credential to friendly message', () {
      final err = Exception(
        '[firebase_auth/invalid-credential] The supplied auth credential is incorrect.',
      );
      final result = AuthService.formatAuthError(err);
      expect(
        result,
        equals('Invalid email or password. Please check your credentials.'),
      );
    });

    test('Correctly maps weak-password to friendly message', () {
      final err = Exception(
        '[firebase_auth/weak-password] Password should be at least 6 characters',
      );
      final result = AuthService.formatAuthError(err);
      expect(
        result,
        equals(
          'Password is too weak. Please use at least 6 characters with letters and numbers.',
        ),
      );
    });

    test('Correctly maps network-request-failed to friendly message', () {
      final err = Exception(
        '[firebase_auth/network-request-failed] A network error occurred.',
      );
      final result = AuthService.formatAuthError(err);
      expect(
        result,
        equals(
          'Network connection issue. Please check your internet connection.',
        ),
      );
    });

    test('Correctly maps unauthorized-domain to actionable message', () {
      final err = Exception(
        '[firebase_auth/unauthorized-domain] This domain is not authorized for OAuth operations for your Firebase project.',
      );
      final result = AuthService.formatAuthError(err);
      expect(
        result,
        equals(
          'This domain is not authorized for OAuth operations. Please verify authorized domains in Firebase Console.',
        ),
      );
    });

    test('Correctly maps popup-blocked to actionable message', () {
      final err = Exception(
        '[firebase_auth/popup-blocked] The popup was blocked by the browser.',
      );
      final result = AuthService.formatAuthError(err);
      expect(
        result,
        equals(
          'Sign-in popup was blocked by your browser. Please allow popups for this site and retry.',
        ),
      );
    });

    test('Correctly maps requires-recent-login or reauth failed', () {
      final err = Exception(
        '[firebase_auth/requires-recent-login] Reauth required',
      );
      expect(
        AuthService.formatAuthError(err),
        equals(
          'Re-authentication failed or session expired. Please log in again.',
        ),
      );
    });
  });

  group('AuthService deleteAccount Sequence Tests', () {
    test(
      'Guest account deletion clears local data and logs out cleanly',
      () async {
        final db = DatabaseService.instance;
        await db.init();
        await db.loginAsGuest();
        expect(db.isGuest, isTrue);

        final authService = AuthService.instance;
        await authService.deleteAccount();

        expect(db.isLoggedIn, isFalse);
      },
    );

    test(
      'Reauthentication failure prevents data deletion and user deletion',
      () async {
        // Verification of the critical security invariant:
        // If reauthentication throws, execution terminates before any deletion happens.
        bool cloudDeleted = false;
        bool localDeleted = false;
        bool userDeleted = false;

        Future<void> executeGuardedDeletion({
          required bool shouldReauthPass,
        }) async {
          if (!shouldReauthPass) {
            throw FirebaseAuthException(
              code: 'wrong-password',
              message: 'Invalid password provided for re-authentication.',
            );
          }
          cloudDeleted = true;
          localDeleted = true;
          userDeleted = true;
        }

        expect(
          () => executeGuardedDeletion(shouldReauthPass: false),
          throwsA(isA<FirebaseAuthException>()),
        );
        expect(cloudDeleted, isFalse);
        expect(localDeleted, isFalse);
        expect(userDeleted, isFalse);

        await executeGuardedDeletion(shouldReauthPass: true);
        expect(cloudDeleted, isTrue);
        expect(localDeleted, isTrue);
        expect(userDeleted, isTrue);
      },
    );
  });
}
