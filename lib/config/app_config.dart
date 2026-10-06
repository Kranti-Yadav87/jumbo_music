/// Application configuration and environment secrets manager.
/// Allows injecting values via `--dart-define` at compile-time or using secure defaults.
class AppConfig {
  AppConfig._();

  /// Supabase endpoint URL for music catalog search and streaming functions
  static const String supabaseEndpoint = String.fromEnvironment(
    'SPOTIFY_ENDPOINT',
    defaultValue:
        'https://uwvsyladvvvjqlgnqppq.supabase.co/functions/v1/spotify',
  );

  /// Supabase anon public key (can be overridden during build)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SPOTIFY_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3dnN5bGFkdnZ2anFsZ25xcHBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNDY3NDEsImV4cCI6MjA4NzgyMjc0MX0.ibwH6IntJjky3uZKxFplDkVGW9bSH0RrwT0cVrd94hI',
  );

  /// Jamendo client id (free at https://devportal.jamendo.com). When set,
  /// search falls back to Jamendo's legal FULL-length tracks before the
  /// 30-second iTunes previews. Pass with --dart-define=JAMENDO_CLIENT_ID=xxx
  static const String jamendoClientId = String.fromEnvironment(
    'JAMENDO_CLIENT_ID',
    defaultValue: '',
  );

  /// Flag indicating whether the unofficial music catalog (Supabase/JioSaavn & iTunes)
  /// is enabled. When false, only the official Jamendo catalog is used.
  /// Pass with --dart-define=USE_UNOFFICIAL_CATALOG=false
  static const bool useUnofficialCatalog = bool.fromEnvironment(
    'USE_UNOFFICIAL_CATALOG',
    defaultValue: true,
  );

  /// Test overrides to allow testing both catalog states without rebuilding
  static bool? mockUseUnofficialCatalog;
  static String? mockJamendoClientId;

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
      'com.jumbomusic.app.channel.audio';
  static const String audioNotificationChannelName = 'Jumbo Music Playback';

  /// Web Client ID / Server Client ID for Google Sign-In backend authentication
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '375294688779-on4vsckpke482km54jl3vsraj0s9ulkt.apps.googleusercontent.com',
  );

  /// Headers map for Supabase API calls
  static Map<String, String> get apiHeaders => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
  };
}
