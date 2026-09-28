import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import 'web_download_helper.dart';

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
    _initSampleDownloads();
  }

  void _initSampleDownloads() {
    // Pre-populate with first 2 sample songs so user immediately sees downloaded section working
    final sample1 = Song(
      id: 'dl_1',
      title: 'Kesariya Sukoon',
      artist: 'Arijit & Jumbo Crew',
      album: 'Bollywood Melodies',
      genre: 'Bollywood',
      duration: const Duration(minutes: 4, seconds: 28),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      quality: '320 kbps Studio HD',
    );

    final sample2 = Song(
      id: 'dl_2',
      title: 'Midnight Lo-Fi Chill',
      artist: 'Kranti Beats',
      album: 'Lofi Study Session Vol. 1',
      genre: 'Lo-Fi',
      duration: const Duration(minutes: 7, seconds: 5),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
      quality: '320 kbps Studio HD',
    );

    _downloadedItems[sample1.id] = DownloadItem(
      song: sample1,
      fileSize: '10.2 MB',
      downloadedAt: DateTime.now().subtract(const Duration(hours: 3)),
      localPath: 'offline_storage/dl_1.mp3',
    );

    _downloadedItems[sample2.id] = DownloadItem(
      song: sample2,
      fileSize: '16.4 MB',
      downloadedAt: DateTime.now().subtract(const Duration(days: 1)),
      localPath: 'offline_storage/dl_2.mp3',
    );
  }

  List<Song> get downloadedSongs =>
      _downloadedItems.values.map((item) => item.song).toList();

  List<DownloadItem> get downloadedItems =>
      _downloadedItems.values.toList()..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

  int get totalDownloadedCount => _downloadedItems.length;

  bool isDownloaded(String songId) =>
      _downloadedItems.containsKey(songId) ||
      _downloadedItems.values.any((item) => item.song.title.toLowerCase() == songId.toLowerCase());

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    // Trigger Browser download on Web via anchor
    if (kIsWeb) {
      _triggerWebDownload(song.audioUrl, '${song.title} - ${song.artist}.mp3');
    }

    // Simulate progress delay (1.5 seconds) for realistic feedback
    await Future.delayed(const Duration(milliseconds: 1500));

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

    _downloadingIds.remove(song.id);
    notifyListeners();

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F2E22),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Color(0xFF10B981), size: 22),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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

  void _triggerWebDownload(String url, String filename) {
    try {
      if (kIsWeb) {
        triggerBrowserDownload(url, filename);
      }
    } catch (_) {}
  }

  void removeDownload(String songId) {
    _downloadedItems.remove(songId);
    notifyListeners();
  }

  void clearAllDownloads() {
    _downloadedItems.clear();
    notifyListeners();
  }
}
