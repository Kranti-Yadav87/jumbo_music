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
import 'services/keyboard_shortcuts_service.dart';

void main() async {
  await CrashReportingService.runWithCrashReporting(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Global Framework Error Boundaries
    CrashReportingService.init();
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return Material(
        color: const Color(0xFF0D0D12),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFF6366F1),
                  size: 44,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Display Error Handled Gracefully',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  errorDetails.exceptionAsString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    };

    // 2. High-Performance Image Cache Limits (Prevents OOM on budget devices)
    PaintingBinding.instance.imageCache.maximumSizeBytes = 120 * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSize = 300;

    // 3. Initialize native background audio notification controls
    if (!kIsWeb) {
      try {
        await JustAudioBackground.init(
          androidNotificationChannelId: AppConfig.audioNotificationChannelId,
          androidNotificationChannelName:
              AppConfig.audioNotificationChannelName,
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidStopForegroundOnPause: false,
          preloadArtwork: true,
        );
      } catch (e) {
        debugPrint('JustAudioBackground init note: $e');
      }
    }

    // 4. Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization note: $e');
    }

    // 5. Initialize persistent database engine, presence sync & network observer
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
        return GlobalKeyboardShortcutsWrapper(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Jumbo Music',
            theme: AppThemeManager.lightTheme,
            darkTheme: AppThemeManager.darkTheme,
            themeMode: themeManager.themeMode,
            home: const AuthGate(),
          ),
        );
      },
    );
  }
}
