import 'downloaded_file.dart';

/// Web: browsers cannot give us a persistent audio file store, so offline
/// downloads are not supported here.
class FileDownloader {
  FileDownloader._();

  static bool get isSupported => false;

  static Future<DownloadedFile> download(String url, String id) {
    throw UnsupportedError('Offline downloads are not supported on web.');
  }

  static Future<bool> exists(String path) async => false;

  static Future<Uri?> playableUri(String path) async => null;

  static Future<void> delete(String path) async {}
}
