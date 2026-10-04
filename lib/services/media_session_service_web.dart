import 'dart:js_interop';
import 'crash_reporting_service.dart';

@JS('jumboMediaUpdateMetadata')
external void _jsUpdateMetadata(
  JSString title,
  JSString artist,
  JSString album,
  JSString coverUrl,
);

@JS('jumboMediaUpdatePlaybackState')
external void _jsUpdatePlaybackState(JSBoolean isPlaying);

@JS('jumboMediaUpdatePositionState')
external void _jsUpdatePositionState(
  JSNumber durationSec,
  JSNumber positionSec,
  JSNumber speed,
);

@JS('jumboRegisterMediaActionHandler')
external void _jsRegisterActionHandler(JSFunction callback);

typedef MediaActionCallback = void Function(String action, double param);

class PlatformMediaSession {
  static MediaActionCallback? _callback;
  static bool _handlerRegistered = false;

  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
    required String coverUrl,
  }) {
    try {
      _jsUpdateMetadata(title.toJS, artist.toJS, album.toJS, coverUrl.toJS);
    } catch (error) {
      CrashReportingService.swallow(error, 'media_session_service_web.dart:38');
    }
  }

  static void updatePlaybackState({required bool isPlaying}) {
    try {
      _jsUpdatePlaybackState(isPlaying.toJS);
    } catch (error) {
      CrashReportingService.swallow(error, 'media_session_service_web.dart:44');
    }
  }

  static void updatePositionState({
    required double durationSeconds,
    required double positionSeconds,
    double playbackRate = 1.0,
  }) {
    try {
      _jsUpdatePositionState(
        durationSeconds.toJS,
        positionSeconds.toJS,
        playbackRate.toJS,
      );
    } catch (error) {
      CrashReportingService.swallow(error, 'media_session_service_web.dart:58');
    }
  }

  static void registerActionHandler(MediaActionCallback callback) {
    _callback = callback;
    if (!_handlerRegistered) {
      _handlerRegistered = true;
      try {
        _jsRegisterActionHandler(_handleJsAction.toJS);
      } catch (error) {
        CrashReportingService.swallow(
          error,
          'media_session_service_web.dart:67',
        );
      }
    }
  }

  static void _handleJsAction(JSString action, JSNumber param) {
    final actionStr = action.toDart;
    final paramNum = param.toDartDouble;
    _callback?.call(actionStr, paramNum);
  }
}
