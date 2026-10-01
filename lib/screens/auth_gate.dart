import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/firestore_sync_service.dart';
import 'login_screen.dart';
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
              child: CircularProgressIndicator(
                color: Color(0xFFFF4B2B),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          // Sync with Firestore & DatabaseService
          if (!db.isLoggedIn) {
            final name = user.displayName ?? user.email?.split('@').first ?? 'User';
            final userId = 'JM-${(user.uid.hashCode.abs() % 90000 + 10000)}';
            db.login(
              email: user.email ?? 'user@jumbomusic.app',
              name: name,
              userId: userId,
            );
            if (user.photoURL != null && user.photoURL!.isNotEmpty) {
              db.updateProfile(avatarUrl: user.photoURL);
            }
            FirestoreSyncService.instance.syncAllUserData();
          }
          return const MainNavigationScreen();
        }

        // Also check if user chose guest mode or local login
        return AnimatedBuilder(
          animation: db,
          builder: (context, _) {
            if (db.isLoggedIn) {
              return const MainNavigationScreen();
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
