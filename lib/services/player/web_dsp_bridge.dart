import 'web_dsp_bridge_stub.dart'
    if (dart.library.js_interop) 'web_dsp_bridge_web.dart'
    as platform;

class WebDspBridge {
  static void applyEqualizer({
    required bool enabled,
    required List<double> gains,
    required double bass,
    required double virtualizer,
    required double loudness,
  }) {
    platform.WebDspBridge.applyEqualizer(
      enabled: enabled,
      gains: gains,
      bass: bass,
      virtualizer: virtualizer,
      loudness: loudness,
    );
  }
}
