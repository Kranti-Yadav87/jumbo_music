import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/firestore_sync_service.dart';
import '../services/crash_reporting_service.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import 'main_navigation_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D15),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4B2B)),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          CrashReportingService.setUserIdentifier(user.uid);
          // Check if user registered via password and is not verified yet
          final isPasswordProvider = user.providerData.any(
            (p) => p.providerId == 'password',
          );
          if (isPasswordProvider && !user.emailVerified) {
            return const EmailVerificationScreen();
          }

          // Authenticated & verified user: sync with DatabaseService under scoped UID
          if (!db.isLoggedIn || db.currentScope != 'user_${user.uid}') {
            final name =
                user.displayName ?? user.email?.split('@').first ?? 'User';
            final userId = 'JM-${(user.uid.hashCode.abs() % 90000 + 10000)}';
            db.login(
              email: user.email ?? 'user@jumbomusic.app',
              name: name,
              userId: userId,
              uid: user.uid,
            );
            if (user.photoURL != null && user.photoURL!.isNotEmpty) {
              db.updateProfile(avatarUrl: user.photoURL);
            }
            FirestoreSyncService.instance.syncAllUserData();
          }
          return const MainNavigationScreen();
        }

        // Guest user or signed out
        CrashReportingService.clearUserIdentifier();
        return AnimatedBuilder(
          animation: db,
          builder: (context, _) {
            if (db.isLoggedIn) {
              return const MainNavigationScreen();
            }
            // Login is the root screen: back must leave the app, never open Home.
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) SystemNavigator.pop();
              },
              child: const LoginScreen(),
            );
          },
        );
      },
    );
  }
}
