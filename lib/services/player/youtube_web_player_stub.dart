/// Stub implementation of YouTubeWebPlayer for native platforms (Android, iOS, desktop).
class YouTubeWebPlayer {
  static bool get isSupported => false;
  static void play(String videoId) {}
  static void pause() {}
  static void resume() {}
  static void stop() {}
  static void seek(double seconds) {}
  static void setVolume(double volume) {}
  static double getCurrentTime() => 0.0;
  static double getDuration() => 0.0;
  static int getState() => -1;
  static void registerCallbacks({
    void Function(int state)? onStateChange,
    void Function(int error)? onError,
  }) {}
}
