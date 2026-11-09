import 'dart:js_interop';

@JS('jumboPlayYouTube')
external void _jsPlayYouTube(JSString videoId);

@JS('jumboPauseYouTube')
external void _jsPauseYouTube();

@JS('jumboResumeYouTube')
external void _jsResumeYouTube();

@JS('jumboStopYouTube')
external void _jsStopYouTube();

@JS('jumboSeekYouTube')
external void _jsSeekYouTube(JSNumber seconds);

@JS('jumboSetYouTubeVolume')
external void _jsSetYouTubeVolume(JSNumber volume);

@JS('jumboGetYouTubeCurrentTime')
external JSNumber _jsGetYouTubeCurrentTime();

@JS('jumboGetYouTubeDuration')
external JSNumber _jsGetYouTubeDuration();

@JS('jumboGetYouTubePlayerState')
external JSNumber _jsGetYouTubePlayerState();

@JS('jumboRegisterYtCallbacks')
external void _jsRegisterYtCallbacks(
  JSFunction onStateChange,
  JSFunction onError,
);

class YouTubeWebPlayer {
  static bool get isSupported => true;

  static void play(String videoId) {
    try {
      _jsPlayYouTube(videoId.toJS);
    } catch (_) {}
  }

  static void pause() {
    try {
      _jsPauseYouTube();
    } catch (_) {}
  }

  static void resume() {
    try {
      _jsResumeYouTube();
    } catch (_) {}
  }

  static void stop() {
    try {
      _jsStopYouTube();
    } catch (_) {}
  }

  static void seek(double seconds) {
    try {
      _jsSeekYouTube(seconds.toJS);
    } catch (_) {}
  }

  static void setVolume(double volume) {
    try {
      _jsSetYouTubeVolume(volume.toJS);
    } catch (_) {}
  }

  static double getCurrentTime() {
    try {
      return _jsGetYouTubeCurrentTime().toDartDouble;
    } catch (_) {
      return 0.0;
    }
  }

  static double getDuration() {
    try {
      return _jsGetYouTubeDuration().toDartDouble;
    } catch (_) {
      return 0.0;
    }
  }

  static int getState() {
    try {
      return _jsGetYouTubePlayerState().toDartInt;
    } catch (_) {
      return -1;
    }
  }

  static void registerCallbacks({
    void Function(int state)? onStateChange,
    void Function(int error)? onError,
  }) {
    try {
      final jsStateChange = ((JSNumber state) {
        onStateChange?.call(state.toDartInt);
      }).toJS;
      final jsError = ((JSNumber error) {
        onError?.call(error.toDartInt);
      }).toJS;
      _jsRegisterYtCallbacks(jsStateChange, jsError);
    } catch (_) {}
  }
}
