import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}