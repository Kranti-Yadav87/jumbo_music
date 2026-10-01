import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  // Initialize persistent database engine
  await DatabaseService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const JumboMusicApp());
}

class JumboMusicApp extends StatelessWidget {
  const JumboMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = AppThemeManager.instance;

    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Jumbo Music',
          theme: AppThemeManager.lightTheme,
          darkTheme: AppThemeManager.darkTheme,
          themeMode: themeManager.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}