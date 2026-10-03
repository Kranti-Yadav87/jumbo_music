import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import '../app_cached_image.dart';
import '../equalizer_bars.dart';
import '../track_options_sheet.dart';

class NowPlayingQueueSheet {
  NowPlayingQueueSheet._();

  static String formatQueueDuration(List<Song> songs) {
    int totalSec = 0;
    for (final s in songs) {
      totalSec += s.duration.inSeconds > 0 ? s.duration.inSeconds : 210;
    }
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
  }

  static void show(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF090F1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return AnimatedBuilder(
              animation: manager,
              builder: (context, _) {
                final song = manager.currentSong;
                final queue = manager.queue;
                final isFav = song != null && manager.isFavorite(song.id);

                return CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Drag Handle
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Queue Header Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.queue_music_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Up Next Queue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${queue.length} songs • ${formatQueueDuration(queue)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (song != null)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131F38),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withOpacity(0.4),
                            ),
                          ),
                          child: ListTile(
                            leading: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppCachedImage(
                                    imageUrl: song.coverUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: EqualizerBars(
                                    isPlaying: manager.isPlaying,
                                    color: const Color(0xFF38BDF8),
                                    height: 14,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Now Playing • ${song.artist}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav
                                    ? const Color(0xFFFF5E7E)
                                    : Colors.white70,
                                size: 22,
                              ),
                              onPressed: () => manager.toggleFavorite(song.id),
                            ),
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(
                      child: Divider(color: Colors.white12, height: 20),
                    ),

                    // Queue List
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = queue[index];
                        final isCurrent = song != null && item.id == song.id;
                        if (isCurrent) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppCachedImage(
                                imageUrl: item.coverUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${item.artist} • ${item.formattedDuration}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white54,
                              ),
                              onPressed: () =>
                                  TrackOptionsSheet.show(context, item),
                            ),
                            onTap: () => manager.playSong(item),
                          ),
                        );
                      }, childCount: queue.length),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
