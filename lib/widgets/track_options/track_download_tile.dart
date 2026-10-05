import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/download_service.dart';

/// Prominent 320kbps Download action tile with progress and delete option.
class TrackDownloadTile extends StatelessWidget {
  final Song song;
  final DownloadService downloadService;

  const TrackDownloadTile({
    super.key,
    required this.song,
    required this.downloadService,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloaded = downloadService.isDownloaded(song.id);
    final isDownloading = downloadService.isDownloading(song.id);
    final fileSize = downloadService.getFileSize(song.id) ?? '10.2 MB';

    return Container(
      decoration: BoxDecoration(
        color: isDownloaded ? const Color(0xFF0F2E22) : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: isDownloaded
            ? Border.all(color: const Color(0xFF10B981).withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        leading: isDownloading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A5A5)),
                ),
              )
            : Icon(
                isDownloaded
                    ? Icons.download_done_rounded
                    : Icons.download_rounded,
                color: isDownloaded ? const Color(0xFF10B981) : Colors.white,
                size: 24,
              ),
        title: Text(
          isDownloaded
              ? 'Downloaded ($fileSize)'
              : isDownloading
              ? 'Downloading (320 kbps)...'
              : 'Download',
          style: TextStyle(
            color: isDownloaded ? const Color(0xFF10B981) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isDownloaded
              ? 'Saved to Library > Downloaded • Offline Ready'
              : 'Save high-quality 320 kbps MP3 to device',
          style: TextStyle(
            color: isDownloaded ? Colors.white70 : const Color(0xFF8E8E93),
            fontSize: 11,
          ),
        ),
        trailing: isDownloaded
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () {
                  downloadService.removeDownload(song.id);
                },
              )
            : null,
        onTap: () {
          if (!isDownloading) {
            downloadService.downloadSong(song, context: context);
          }
        },
      ),
    );
  }
}
