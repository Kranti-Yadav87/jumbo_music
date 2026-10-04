import 'dart:js_interop';

import 'downloaded_file.dart';
import '../crash_reporting_service.dart';

// Helpers implemented in web/index.html (Cache Storage API).
@JS('jumboOfflineSave')
external JSPromise<JSNumber> _jsSave(JSString url, JSString id);

@JS('jumboOfflineHas')
external JSPromise<JSBoolean> _jsHas(JSString id);

@JS('jumboOfflineObjectUrl')
external JSPromise<JSString> _jsObjectUrl(JSString id);

@JS('jumboOfflineDelete')
external JSPromise<JSBoolean> _jsDelete(JSString id);

/// Offline downloads in the browser, stored in Cache Storage.
/// Works only when the audio host allows cross-origin reads (CORS); otherwise
/// [download] throws and the UI explains it.
class FileDownloader {
  FileDownloader._();

  static const String _prefix = 'web-offline:';

  static bool get isSupported => true;

  static String _idOf(String path) => path.substring(_prefix.length);

  static Future<DownloadedFile> download(String url, String id) async {
    final size = (await _jsSave(url.toJS, id.toJS).toDart).toDartInt;
    if (size <= 0) {
      throw StateError('Browser could not download this file (CORS blocked).');
    }
    return DownloadedFile(path: '$_prefix$id', bytes: size);
  }

  static Future<bool> exists(String path) async {
    if (!path.startsWith(_prefix)) return false;
    try {
      final res = (await _jsHas(_idOf(path).toJS).toDart).toDart;
      return res;
    } catch (_) {
      return false;
    }
  }

  static Future<Uri?> playableUri(String path) async {
    if (!path.startsWith(_prefix)) return null;
    try {
      final url = (await _jsObjectUrl(_idOf(path).toJS).toDart).toDart;
      return url.isEmpty ? null : Uri.parse(url);
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete(String path) async {
    if (!path.startsWith(_prefix)) return;
    try {
      await _jsDelete(_idOf(path).toJS).toDart;
    } catch (error) {
      CrashReportingService.swallow(error, 'file_downloader_web.dart:62');
    }
  }
}
