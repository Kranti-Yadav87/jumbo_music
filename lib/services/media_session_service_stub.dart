typedef MediaActionCallback = void Function(String action, double param);

class PlatformMediaSession {
  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
    required String coverUrl,
  }) {}

  static void updatePlaybackState({required bool isPlaying}) {}

  static void updatePositionState({
    required double durationSeconds,
    required double positionSeconds,
    double playbackRate = 1.0,
  }) {}

  static void registerActionHandler(MediaActionCallback callback) {}
}
