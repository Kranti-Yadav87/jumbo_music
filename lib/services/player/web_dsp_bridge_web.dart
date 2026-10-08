import 'dart:js_interop';
import '../crash_reporting_service.dart';

@JS('jumboApplyEQ')
external void _jsApplyEQ(
  JSBoolean enabled,
  JSArray<JSNumber> gains,
  JSNumber bass,
  JSNumber virtualizer,
  JSNumber loudness,
);

class WebDspBridge {
  static void applyEqualizer({
    required bool enabled,
    required List<double> gains,
    required double bass,
    required double virtualizer,
    required double loudness,
  }) {
    try {
      final jsGains = gains.map((g) => g.toJS).toList().toJS;
      _jsApplyEQ(
        enabled.toJS,
        jsGains,
        bass.toJS,
        virtualizer.toJS,
        loudness.toJS,
      );
    } catch (error) {
      CrashReportingService.swallow(error, 'web_dsp_bridge_web.dart:28');
    }
  }
}
