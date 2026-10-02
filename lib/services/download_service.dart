import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import 'database_service.dart';

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

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  final Map<String, DownloadItem> _downloadedItems = {};
  final Set<String> _downloadingIds = {};

  DownloadService._internal() {
    _hydrateFromDatabase();
  }

  void _hydrateFromDatabase() {
    final db = DatabaseService.instance;
    final savedDownloads = db.rawDownloads;

    _downloadedItems.clear();
    if (savedDownloads.isNotEmpty) {
      for (final item in savedDownloads) {
        if (item['song'] != null && item['song'] is Map<String, dynamic>) {
          final song = Song.fromJson(item['song'] as Map<String, dynamic>);
          // Filter out and remove any old mock sample songs
          if (song.id == 'dl_1' ||
              song.id == 'dl_2' ||
              song.id.startsWith('sample_') ||
              song.title == 'Kesariya Sukoon' ||
              song.title == 'Midnight Lo-Fi Chill') {
            db.removeDownload(song.id);
            continue;
          }
          final dAt = item['downloadedAt'] != null
              ? DateTime.tryParse(item['downloadedAt'] as String) ??
                    DateTime.now()
              : DateTime.now();
          _downloadedItems[song.id] = DownloadItem(
            song: song,
            fileSize: (item['fileSize'] as String?) ?? '10.2 MB',
            downloadedAt: dAt,
            localPath:
                (item['localPath'] as String?) ??
                'offline_storage/${song.id}.mp3',
          );
        }
      }
    }
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

  Future<void> downloadSong(Song song, {BuildContext? context}) async {
    if (isDownloaded(song.id)) {
      if (context != null && context.mounted) {
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
                  'Downloading "${song.title}" (320 kbps MP3)...',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Simulate realistic 320kbps progress and cache storage
    await Future.delayed(const Duration(milliseconds: 1200));

    // Calculate approximate 320kbps MP3 file size
    final sec = song.duration.inSeconds > 0 ? song.duration.inSeconds : 240;
    final mb = (sec * 320 / 8 / 1024).clamp(3.5, 25.0);
    final sizeStr = '${mb.toStringAsFixed(1)} MB';

    _downloadedItems[song.id] = DownloadItem(
      song: song,
      fileSize: sizeStr,
      downloadedAt: DateTime.now(),
      localPath: 'offline_storage/${song.id}.mp3',
    );

    // Persist to DatabaseService
    DatabaseService.instance.saveDownload(
      song: song,
      fileSize: sizeStr,
      localPath: 'offline_storage/${song.id}.mp3',
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
                      '$sizeStr • 320 kbps Master • Saved to Library > Downloaded',
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
    _downloadedItems.remove(songId);
    DatabaseService.instance.removeDownload(songId);
    notifyListeners();
  }

  void clearAllDownloads() {
    for (final id in _downloadedItems.keys) {
      DatabaseService.instance.removeDownload(id);
    }
    _downloadedItems.clear();
    notifyListeners();
  }
}
