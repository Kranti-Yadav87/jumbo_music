import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'services/database_service.dart';
import 'services/download_service.dart';
import 'services/theme_service.dart';
import 'services/connectivity_service.dart';
import 'services/presence_service.dart';
import 'services/crash_reporting_service.dart';
import 'screens/auth_gate.dart';

void main() async {
  await CrashReportingService.runWithCrashReporting(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize native background audio notification controls
    if (!kIsWeb) {
      try {
        await JustAudioBackground.init(
          androidNotificationChannelId: AppConfig.audioNotificationChannelId,
          androidNotificationChannelName: AppConfig.audioNotificationChannelName,
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
        );
      } catch (e) {
        debugPrint('JustAudioBackground init note: $e');
      }
    }

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization note: $e');
    }

    // Initialize persistent database engine, presence sync & network observer
    await DatabaseService.instance.init();
    DownloadService().hydrateFromDatabase();
    PresenceService.instance.init();
    ConnectivityService.instance; // warm-up connectivity listener

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF000000),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    runApp(const JumboMusicApp());
  });
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
