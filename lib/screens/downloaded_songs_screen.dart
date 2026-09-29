import 'package:flutter/material.dart';
import '../services/download_service.dart';
import '../services/music_player_manager.dart';
import '../widgets/track_options_sheet.dart';

class DownloadedSongsScreen extends StatelessWidget {
  const DownloadedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadService = DownloadService();
    final playerManager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: Listenable.merge([downloadService, playerManager]),
      builder: (context, _) {
        final items = downloadService.downloadedItems;
        final songs = downloadService.downloadedSongs;

        return Scaffold(
          backgroundColor: const Color(0xFF09090F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D0D12),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Downloaded Songs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  tooltip: 'Clear All Downloads',
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white60),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: const Text('Clear Downloads', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Are you sure you want to remove all downloaded songs from offline storage?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () {
                              downloadService.clearAllDownloads();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          size: 64,
                          color: Colors.white30,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'No Downloaded Songs Yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Tap the 3-dots menu on any song or in track options to download 320 kbps tracks for offline playback.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${items.length} tracks offline • High Fidelity 320 kbps',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Play All Offline Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text(
                                'Play All Offline',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              onPressed: () {
                                playerManager.playPlaylist(songs, initialIndex: 0);
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    final item = items[index - 1];
                    final isCurrent = playerManager.currentSong?.id == item.song.id;
                    final isPlaying = isCurrent && playerManager.isPlaying;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF1A1A2E) : const Color(0xFF141418),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF6366F1).withOpacity(0.4)
                              : Colors.white.withOpacity(0.04),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                item.song.coverUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF2C2C2E),
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.pause_rounded,
                                  color: Color(0xFF818CF8),
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          item.song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? const Color(0xFF818CF8) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${item.song.artist} • ${item.fileSize}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                              onPressed: () {
                                TrackOptionsSheet.show(context, item.song);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          playerManager.playSong(item.song, newQueue: songs);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
