import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/auth_service.dart';

void main() {
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
  });
}
