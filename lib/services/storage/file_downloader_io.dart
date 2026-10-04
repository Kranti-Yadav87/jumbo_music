import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'downloaded_file.dart';
import '../crash_reporting_service.dart';

/// Real offline downloads for Android, iOS and desktop.
class FileDownloader {
  FileDownloader._();

  static bool get isSupported => true;

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}offline_audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeName(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  /// Streams [url] to disk. Writes to a `.part` file first so an interrupted
  /// download never leaves a corrupt "finished" file behind.
  static Future<DownloadedFile> download(String url, String id) async {
    final dir = await _dir();
    final target = File(
      '${dir.path}${Platform.pathSeparator}${_safeName(id)}.mp3',
    );
    final tmp = File('${target.path}.part');
    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      final sink = tmp.openWrite();
      var total = 0;
      try {
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          total += chunk.length;
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      if (total == 0) {
        throw const HttpException('Empty response');
      }
      if (await target.exists()) {
        await target.delete();
      }
      await tmp.rename(target.path);
      return DownloadedFile(path: target.path, bytes: total);
    } catch (_) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (error) {
        CrashReportingService.swallow(error, 'file_downloader_io.dart:63');
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<File?> _resolveFile(String path) async {
    final direct = File(path);
    if (await direct.exists()) return direct;
    try {
      final fileName = path.split(Platform.pathSeparator).last;
      if (fileName.isNotEmpty) {
        final dir = await _dir();
        final candidate = File('${dir.path}${Platform.pathSeparator}$fileName');
        if (await candidate.exists()) return candidate;
      }
    } catch (error) {
      CrashReportingService.swallow(error, 'file_downloader_io.dart:80');
    }
    return null;
  }

  static Future<bool> exists(String path) async {
    final f = await _resolveFile(path);
    return f != null;
  }

  /// Address the audio player can open, or null when the file is gone.
  static Future<Uri?> playableUri(String path) async {
    final f = await _resolveFile(path);
    if (f != null) {
      return Uri.file(f.path);
    }
    return null;
  }

  static Future<void> delete(String path) async {
    try {
      final f = await _resolveFile(path);
      if (f != null && await f.exists()) {
        await f.delete();
      }
    } catch (error) {
      CrashReportingService.swallow(error, 'file_downloader_io.dart:104');
    }
  }
}
