import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jumbo_music/services/auth_service.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/storage/storage_engine.dart';
import 'package:jumbo_music/widgets/auth_dialog.dart';

class FakeUserCredential implements UserCredential {
  @override
  final AuthCredential? credential = null;
  @override
  final AdditionalUserInfo? additionalUserInfo = null;
  @override
  final User? user = null;
}

class FakeAuthService extends AuthService {
  bool shouldThrow = false;
  Object? errorToThrow;
  String? lastEmail;
  String? lastName;
  bool googleSignInCalled = false;

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldThrow) {
      throw errorToThrow ??
          Exception(
            '[firebase_auth/invalid-credential] The supplied auth credential is incorrect.',
          );
    }
    lastEmail = email;
    DatabaseService.instance.setMockProfile(
      email: email,
      name: email.split('@').first,
      userId: 'JM-12345',
      isLoggedIn: true,
    );
    return FakeUserCredential();
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (shouldThrow) {
      throw errorToThrow ??
          Exception(
            '[firebase_auth/email-already-in-use] The email address is already in use by another account.',
          );
    }
    lastName = name;
    lastEmail = email;
    DatabaseService.instance.setMockProfile(
      email: email,
      name: name,
      userId: 'JM-67890',
      isLoggedIn: true,
    );
    return FakeUserCredential();
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    if (shouldThrow) {
      throw errorToThrow ??
          Exception('[firebase_auth/popup-blocked] Popup was blocked.');
    }
    googleSignInCalled = true;
    DatabaseService.instance.setMockProfile(
      email: 'google.user@jumbo.app',
      name: 'Google User',
      userId: 'JM-55555',
      isLoggedIn: true,
    );
    return FakeUserCredential();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableAuthDialog({bool isSignUp = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () => AuthDialog.show(context, isSignUp: isSignUp),
                child: const Text('Open Auth Dialog'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('AuthDialog Widget Tests', () {
    late FakeAuthService fakeAuth;
    late DatabaseService db;

    setUp(() async {
      StorageEngine.inMemoryOnly = true;
      StorageEngine.clearMemoryStorage();

      fakeAuth = FakeAuthService();
      AuthService.instance = fakeAuth;

      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();
    });

    tearDown(() async {
      AuthService.resetInstance();
      await db.clearAllUserData();
      StorageEngine.clearMemoryStorage();
      StorageEngine.inMemoryOnly = false;
    });

    testWidgets(
      'Sign In Happy Path: Submitting valid credentials signs in and displays welcome message',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableAuthDialog(isSignUp: false));
        await tester.pumpAndSettle();

        // Open Dialog
        await tester.tap(find.text('Open Auth Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to Jumbo'), findsOneWidget);
        expect(find.text('Sign in to sync your playlists & ID'), findsOneWidget);

        // Enter email and password
        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(2));
        await tester.enterText(textFields.at(0), 'alice@example.com');
        await tester.enterText(textFields.at(1), 'secret123');
        await tester.pumpAndSettle();

        // Tap Sign In button
        final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
        await tester.tap(signInBtn);
        // Wait for async auth and dialog pop transition
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // Verify dialog closed and SnackBar shown
        expect(find.byType(AuthDialog), findsNothing);
        expect(find.text('Welcome back, alice! 🎉'), findsOneWidget);
        expect(fakeAuth.lastEmail, equals('alice@example.com'));
      },
    );

    testWidgets(
      'Sign Up Happy Path: Switching to Sign Up, entering details registers account',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableAuthDialog(isSignUp: true));
        await tester.pumpAndSettle();

        // Open Dialog in Sign Up mode
        await tester.tap(find.text('Open Auth Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsWidgets);
        expect(find.text('Full Name'), findsOneWidget);

        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(3));

        await tester.enterText(textFields.at(0), 'Bob Builder');
        await tester.enterText(textFields.at(1), 'bob@example.com');
        await tester.enterText(textFields.at(2), 'bobpassword123');
        await tester.pumpAndSettle();

        // Tap Create Account
        final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.byType(AuthDialog), findsNothing);
        expect(
          find.text('Account created! Check inbox to verify your email 🎉'),
          findsOneWidget,
        );
        expect(fakeAuth.lastName, equals('Bob Builder'));
        expect(fakeAuth.lastEmail, equals('bob@example.com'));
      },
    );

    testWidgets(
      'Continue as Guest Happy Path: Logs in guest and shows SnackBar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableAuthDialog());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Auth Dialog'));
        await tester.pumpAndSettle();

        final guestBtn = find.text('Continue as Guest');
        expect(guestBtn, findsOneWidget);

        await tester.tap(guestBtn);
        // Advance 300ms timer
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.byType(AuthDialog), findsNothing);
        expect(find.textContaining('Exploring in Guest Mode!'), findsOneWidget);
      },
    );

    testWidgets(
      'Google Sign-In Happy Path: Logs in via Google and shows SnackBar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableAuthDialog());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Auth Dialog'));
        await tester.pumpAndSettle();

        final googleBtn = find.text('Continue with Google');
        expect(googleBtn, findsOneWidget);

        await tester.tap(googleBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.byType(AuthDialog), findsNothing);
        expect(
          find.text('Signed in with Google as Google User! 🚀'),
          findsOneWidget,
        );
        expect(fakeAuth.googleSignInCalled, isTrue);
      },
    );

    testWidgets(
      'Validation Error States: Shows inline error on empty email or short password',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableAuthDialog());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Auth Dialog'));
        await tester.pumpAndSettle();

        final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');

        // 1. Empty email
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Please enter a valid email address'),
          findsOneWidget,
        );

        // 2. Invalid email format
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'notanemail');
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Please enter a valid email address'),
          findsOneWidget,
        );

        // 3. Short password
        await tester.enterText(textFields.at(0), 'valid@example.com');
        await tester.enterText(textFields.at(1), '123');
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Backend Error State: Displays formatted error banner when AuthService throws',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        fakeAuth.shouldThrow = true;
        fakeAuth.errorToThrow = Exception(
          '[firebase_auth/invalid-credential] The supplied auth credential is incorrect.',
        );

        await tester.pumpWidget(buildTestableAuthDialog());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Auth Dialog'));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'wrong@example.com');
        await tester.enterText(textFields.at(1), 'wrongpassword');

        final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();

        // Dialog stays open and displays friendly error
        expect(find.byType(AuthDialog), findsOneWidget);
        expect(
          find.text('Invalid email or password. Please check your credentials.'),
          findsOneWidget,
        );
      },
    );
  });
}
