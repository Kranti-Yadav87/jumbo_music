import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import 'equalizer_bars.dart';
import 'track_options_sheet.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final int? index;
  final VoidCallback? onTap;
  final List<Song>? playlistContext;

  const SongTile({
    super.key,
    required this.song,
    this.index,
    this.onTap,
    this.playlistContext,
  });

  @override
  Widget build(BuildContext context) {
    final playerManager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: playerManager,
      builder: (context, _) {
        final isCurrent = playerManager.currentSong?.id == song.id;
        final isPlaying = isCurrent && playerManager.isPlaying;
        final isFav = playerManager.isFavorite(song.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFF6366F1).withOpacity(0.18)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFF6366F1).withOpacity(0.4)
                  : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap ??
                  () {
                    playerManager.playSong(
                      song,
                      newQueue: playlistContext,
                    );
                  },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (index != null)
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Text(
                          '$index',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? const Color(0xFF818CF8)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    if (index != null) const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            song.coverUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 50,
                              height: 50,
                              color: const Color(0xFF262638),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              width: 50,
                              height: 50,
                              color: Colors.black45,
                              alignment: Alignment.center,
                              child: EqualizerBars(
                                isPlaying: isPlaying,
                                color: const Color(0xFF818CF8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? const Color(0xFF818CF8)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${song.artist} • ${song.formattedDuration}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? const Color(0xFFEF4444) : Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: () {
                        playerManager.toggleFavorite(song.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () {
                        TrackOptionsSheet.show(context, song);
                      },
                    ),
                    Icon(
                      isCurrent && isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: isCurrent
                          ? const Color(0xFF818CF8)
                          : Colors.grey.shade400,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
