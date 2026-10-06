import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import 'database_service.dart';
import 'download_utils.dart';
import 'storage/file_downloader.dart';

class DownloadItem {
  final Song song;
  final String fileSize;
  final DateTime downloadedAt;
  final String localPath;

  const DownloadItem({
    required this.song,
    required this.fileSize,
    required this.downloadedAt,
    required this.localPath,
  });
}

abstract class FileDownloaderDelegate {
  bool get isSupported;
  Future<DownloadedFile> download(String url, String id);
  Future<bool> exists(String path);
  Future<Uri?> playableUri(String path);
  Future<void> delete(String path);
}

class DefaultFileDownloaderDelegate implements FileDownloaderDelegate {
  const DefaultFileDownloaderDelegate();

  @override
  bool get isSupported => FileDownloader.isSupported;

  @override
  Future<DownloadedFile> download(String url, String id) =>
      FileDownloader.download(url, id);

  @override
  Future<bool> exists(String path) => FileDownloader.exists(path);

  @override
  Future<Uri?> playableUri(String path) => FileDownloader.playableUri(path);

  @override
  Future<void> delete(String path) => FileDownloader.delete(path);
}

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  static FileDownloaderDelegate delegate =
      const DefaultFileDownloaderDelegate();

  final Map<String, DownloadItem> _downloadedItems = {};
  final Set<String> _downloadingIds = {};

  DownloadService._internal() {
    _hydrateFromDatabase();
    DatabaseService.instance.addListener(_onDatabaseChanged);
  }

  void _onDatabaseChanged() {
    _hydrateFromDatabase();
  }

  void hydrateFromDatabase() => _hydrateFromDatabase();

  void _hydrateFromDatabase() {
    final db = DatabaseService.instance;
    final savedDownloads = db.rawDownloads;

    _downloadedItems.clear();
    if (savedDownloads.isNotEmpty) {
      for (final item in savedDownloads) {
        if (item['song'] != null && item['song'] is Map<String, dynamic>) {
          final song = Song.fromJson(item['song'] as Map<String, dynamic>);
          // Filter out any old mock sample songs
          if (song.id == 'dl_1' ||
              song.id == 'dl_2' ||
              song.id.startsWith('sample_') ||
              song.title == 'Kesariya Sukoon' ||
              song.title == 'Midnight Lo-Fi Chill') {
            continue;
          }
          // Older versions only simulated downloads (no file on disk). Drop them
          // so the library never claims a song is offline when it is not.
          final savedPath = (item['localPath'] as String?) ?? '';
          if (savedPath.isEmpty || savedPath.startsWith('offline_storage/')) {
            continue;
          }
          final dAt = item['downloadedAt'] != null
              ? DateTime.tryParse(item['downloadedAt'] as String) ??
                    DateTime.now()
              : DateTime.now();
          _downloadedItems[song.id] = DownloadItem(
            song: song,
            fileSize: (item['fileSize'] as String?) ?? '',
            downloadedAt: dAt,
            localPath: savedPath,
          );
        }
      }
    }
    notifyListeners();
  }

  List<Song> get downloadedSongs =>
      _downloadedItems.values.map((item) => item.song).toList();

  List<DownloadItem> get downloadedItems =>
      _downloadedItems.values.toList()
        ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

  int get totalDownloadedCount => _downloadedItems.length;

  bool isDownloaded(String songId) =>
      _downloadedItems.containsKey(songId) ||
      _downloadedItems.values.any(
        (item) => item.song.title.toLowerCase() == songId.toLowerCase(),
      );

  bool isDownloading(String songId) => _downloadingIds.contains(songId);

  String? getFileSize(String songId) {
    if (_downloadedItems.containsKey(songId)) {
      return _downloadedItems[songId]?.fileSize;
    }
    return null;
  }

  void _toast(BuildContext? context, String message, {Color? color}) {
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color ?? const Color(0xFF262630),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  DownloadItem? findDownloadedItem(String songId, {String? title}) {
    if (_downloadedItems.containsKey(songId)) {
      return _downloadedItems[songId];
    }
    if (title != null && title.trim().isNotEmpty) {
      final t = title.trim().toLowerCase();
      for (final item in _downloadedItems.values) {
        if (item.song.title.trim().toLowerCase() == t) {
          return item;
        }
      }
    }
    final cleanId = songId.trim().toLowerCase();
    for (final item in _downloadedItems.values) {
      if (item.song.id.toLowerCase() == cleanId ||
          item.song.title.toLowerCase() == cleanId) {
        return item;
      }
    }
    return null;
  }

  /// Playable address of the offline copy when it really exists, else null
  /// (caller then streams from the network).
  Future<Uri?> playableUriFor(String songId, {String? title}) async {
    final item = findDownloadedItem(songId, title: title);
    if (item == null || !delegate.isSupported) {
      debugPrint(
        '[DownloadService] playableUriFor($songId): item is null or delegate not supported',
      );
      return null;
    }
    final exists = await delegate.exists(item.localPath);
    debugPrint(
      '[DownloadService] EXISTS-CHECK for "$songId" at "${item.localPath}": $exists',
    );
    if (!exists) return null;
    final uri = await delegate.playableUri(item.localPath);
    debugPrint('[DownloadService] PLAYABLE URI for "$songId": $uri');
    return uri;
  }

  Future<void> downloadSong(Song song, {BuildContext? context}) async {
    if (!delegate.isSupported) {
      _toast(context, 'Offline downloads are not supported on this device.');
      return;
    }
    if (song.audioUrl.trim().isEmpty ||
        (!song.audioUrl.startsWith('http://') &&
            !song.audioUrl.startsWith('https://'))) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF262630),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.amberAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Offline download is not available for "${song.title}" due to licensing or source stream restrictions.',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    if (isDownloaded(song.id) || isDownloading(song.id)) {
      if (isDownloaded(song.id) && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '"${song.title}" is already in your Downloaded library!',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    _downloadingIds.add(song.id);
    notifyListeners();
    debugPrint(
      '[Download] START: Downloading "${song.title}" (${song.id}) from ${song.audioUrl}',
    );

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E1E2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Downloading "${song.title}" ...',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final DownloadedFile file;
    try {
      file = await delegate.download(song.audioUrl, song.id);
      debugPrint(
        '[Download] BYTES: Received ${file.bytes} bytes for "${song.title}" (${song.id})',
      );
      debugPrint(
        '[Download] SAVED PATH: File saved at "${file.path}" for "${song.title}"',
      );
    } catch (e) {
      debugPrint('[Download] FAILED for ${song.id}: $e');
      _downloadingIds.remove(song.id);
      notifyListeners();
      if (context != null && context.mounted) {
        _toast(
          context,
          kIsWeb
              ? 'Browser cannot save offline audio due to host CORS policy. Use Android app for full offline caching.'
              : 'Download failed for "${song.title}". Check your connection and try again.',
          color: const Color(0xFF3B1D1D),
        );
      }
      return;
    }

    final sizeStr = formatBytes(file.bytes);

    _downloadedItems[song.id] = DownloadItem(
      song: song,
      fileSize: sizeStr,
      downloadedAt: DateTime.now(),
      localPath: file.path,
    );

    DatabaseService.instance.saveDownload(
      song: song,
      fileSize: sizeStr,
      localPath: file.path,
    );

    _downloadingIds.remove(song.id);
    notifyListeners();

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F2E22),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.download_done_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloaded "${song.title}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$sizeStr • Saved to Library > Downloaded',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void removeDownload(String songId) {
    debugPrint('[Download] REMOVE: Deleting download for "$songId"');
    final item = _downloadedItems.remove(songId);
    if (item != null) unawaited(delegate.delete(item.localPath));
    DatabaseService.instance.removeDownload(songId);
    notifyListeners();
  }

  void clearAllDownloads() {
    debugPrint(
      '[Download] CLEAR ALL: Deleting all ${_downloadedItems.length} downloads',
    );
    for (final entry in _downloadedItems.entries) {
      DatabaseService.instance.removeDownload(entry.key);
      unawaited(delegate.delete(entry.value.localPath));
    }
    _downloadedItems.clear();
    notifyListeners();
  }
}
