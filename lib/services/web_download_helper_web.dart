import 'dart:js_interop';

@JS('downloadAudioFile')
external void _downloadAudioFile(JSString url, JSString filename);

void triggerBrowserDownload(String url, String filename) {
  try {
    _downloadAudioFile(url.toJS, filename.toJS);
  } catch (_) {}
}
