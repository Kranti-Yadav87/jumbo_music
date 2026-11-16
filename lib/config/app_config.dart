import '../services/database_service.dart';

/// Application configuration and environment secrets manager.
/// Allows injecting values via `--dart-define` at compile-time or using secure defaults.
class AppConfig {
  AppConfig._();

  /// Jamendo client id (free at https://devportal.jamendo.com). When set,
  /// search falls back to Jamendo's legal FULL-length tracks before the
  /// 30-second iTunes previews. Pass with --dart-define=JAMENDO_CLIENT_ID=xxx
  static const String jamendoClientId = String.fromEnvironment(
    'JAMENDO_CLIENT_ID',
    defaultValue: '',
  );

  /// Controls whether YouTube and iTunes catalog search is enabled.
  /// When false, search uses only the Jamendo catalog.
  /// Pass with --dart-define=USE_UNOFFICIAL_CATALOG=false
  static const bool useUnofficialCatalog = bool.fromEnvironment(
    'USE_UNOFFICIAL_CATALOG',
    defaultValue: true,
  );

  /// Test overrides to allow testing both catalog states without rebuilding
  static bool? mockUseUnofficialCatalog;
  static String? mockJamendoClientId;
  static String? mockGeminiApiKey;

  /// Effective catalog flag (respects mock override in tests)
  static bool get isUnofficialCatalogEnabled =>
      mockUseUnofficialCatalog ?? useUnofficialCatalog;

  /// Effective Jamendo client ID (respects mock override in tests)
  static String get activeJamendoClientId =>
      mockJamendoClientId ?? jamendoClientId;

  /// App name & version metadata
  static const String appName = 'Jumbo Music';
  static const String appVersion = '2.0.0';

  /// Public web address used in share messages on mobile/desktop.
  static const String webAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://jumbo-music-ff58c.web.app',
  );

  /// Android APK published by .github/workflows/build-apk.yml
  static const String apkDownloadUrl = String.fromEnvironment(
    'APK_URL',
    defaultValue:
        'https://github.com/Kranti-Yadav87/jumbo_music/releases/latest/download/app-release.apk',
  );

  /// Default notification channel ID for background audio
  static const String audioNotificationChannelId =
      'com.jumbomusic.app.channel.audio.v3';
  static const String audioNotificationChannelName = 'Jumbo Music Playback';

  /// Web Client ID / Server Client ID for Google Sign-In backend authentication
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '375294688779-on4vsckpke482km54jl3vsraj0s9ulkt.apps.googleusercontent.com',
  );

  /// Optional user-provided Gemini API key. Do not inject private keys into client builds.
  static String get geminiApiKey {
    if (mockGeminiApiKey != null) return mockGeminiApiKey!;
    try {
      final fromDb =
          DatabaseService.instance.getSetting('gemini_api_key')?.toString() ??
          '';
      if (fromDb.isNotEmpty) return fromDb;
    } catch (_) {}
    return '';
  }

  /// Optional user-provided YouTube Music key for native clients.
  /// Web requests use the same-origin API proxy; never compile a private key into a client.
}
