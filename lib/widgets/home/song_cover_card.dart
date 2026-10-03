import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import '../../services/theme_service.dart';
import '../app_cached_image.dart';

/// Horizontal list of square song cards used by the home sections.
class SongCoverRow extends StatelessWidget {
  final List<Song> songs;
  final double height;

  const SongCoverRow({super.key, required this.songs, this.height = 215});

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: manager,
        builder: (context, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isCurrent = manager.currentSong?.id == song.id;
              final showPause = isCurrent && manager.isPlaying;
              return GestureDetector(
                onTap: () {
                  if (isCurrent) {
                    manager.togglePlay();
                  } else {
                    manager.playSong(song, newQueue: songs);
                  }
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            AppCachedImage(
                              imageUrl: song.coverUrl,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  showPause
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isCurrent
                              ? const Color(0xFFFF5E3A)
                              : AppThemeManager.textPrimary(context),
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppThemeManager.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
