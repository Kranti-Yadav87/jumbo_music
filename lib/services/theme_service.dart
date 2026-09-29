import 'package:flutter/material.dart';
import 'database_service.dart';

class AppThemeManager extends ChangeNotifier {
  static final AppThemeManager _instance = AppThemeManager._internal();
  factory AppThemeManager() => _instance;
  static AppThemeManager get instance => _instance;

  ThemeMode _themeMode = ThemeMode.dark;

  AppThemeManager._internal() {
    _loadFromDatabase();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadFromDatabase() {
    final db = DatabaseService.instance;
    final isDark = db.getSetting('isDarkMode', true) as bool;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    DatabaseService.instance.updateSetting('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    DatabaseService.instance.updateSetting('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  // --- Dynamic Color Helpers ---
  static Color scaffoldBg(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color cardBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF14141E)
        : const Color(0xFFFFFFFF);
  }

  static Color cardBgSubtle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A26)
        : const Color(0xFFF1F5F9);
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white60
        : const Color(0xFF64748B);
  }

  static Color textMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white38
        : const Color(0xFF94A3B8);
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
  }

  static Color bottomBarBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0C0C0E)
        : const Color(0xFFFFFFFF);
  }

  // --- Complete Theme Definitions ---

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF80C8DE),
      surface: Color(0xFF14141E),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF14141E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF14141E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF14141E),
      surfaceTintColor: Colors.transparent,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Modern clean zinc slate
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4F46E5),
      secondary: Color(0xFF0EA5E9),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
