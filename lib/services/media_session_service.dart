import 'media_session_service_stub.dart'
    if (dart.library.js_interop) 'media_session_service_web.dart'
    as platform;

typedef MediaActionCallback = void Function(String action, double param);

class MediaSessionService {
  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
    required String coverUrl,
  }) {
    platform.PlatformMediaSession.updateMetadata(
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
    );
  }

  static void updatePlaybackState({required bool isPlaying}) {
    platform.PlatformMediaSession.updatePlaybackState(isPlaying: isPlaying);
  }

  static void updatePositionState({
    required double durationSeconds,
    required double positionSeconds,
    double playbackRate = 1.0,
  }) {
    platform.PlatformMediaSession.updatePositionState(
      durationSeconds: durationSeconds,
      positionSeconds: positionSeconds,
      playbackRate: playbackRate,
    );
  }

  static void registerActionHandler(MediaActionCallback callback) {
    platform.PlatformMediaSession.registerActionHandler(callback);
  }
}
