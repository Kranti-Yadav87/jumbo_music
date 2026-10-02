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

  /// App name & version metadata
  static const String appName = 'Jumbo Music';
  static const String appVersion = '2.0.0 Pro';

  /// Default notification channel ID for background audio
  static const String audioNotificationChannelId =
      'com.example.jumbo_music.channel.audio';
  static const String audioNotificationChannelName = 'Jumbo Music Playback';

  /// Headers map for Supabase API calls
  static Map<String, String> get apiHeaders => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
  };
}
