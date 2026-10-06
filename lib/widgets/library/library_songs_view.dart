import 'package:flutter/material.dart';
import '../../services/music_player_manager.dart';
import '../cover_image.dart';
import '../track_options_sheet.dart';

/// Sliver content for the 'Songs' category in LibraryTab.
class LibrarySongsSliverView extends StatelessWidget {
  final MusicPlayerManager manager;
  final bool isDark;
  final Color cardColor;
  final Color cardBorder;

  const LibrarySongsSliverView({
    super.key,
    required this.manager,
    required this.isDark,
    required this.cardColor,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = manager.allSongs[index];
        final isCurrent = manager.currentSong?.id == song.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFF38BDF8).withOpacity(0.5)
                  : cardBorder,
            ),
          ),
          child: ListTile(
            leading: CoverImage(
              imageUrl: song.coverUrl,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(10),
              fallbackBgColor: const Color(0xFF1E293B),
              fallbackIcon: Icons.music_note,
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrent
                    ? const Color(0xFF38BDF8)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${song.artist} • ${song.formattedDuration}',
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () => TrackOptionsSheet.show(context, song),
            ),
            onTap: () {
              final isCurrent = manager.currentSong?.id == song.id;
              if (isCurrent) {
                manager.togglePlay();
              } else {
                manager.playSong(song, newQueue: manager.allSongs);
              }
            },
          ),
        );
      }, childCount: manager.allSongs.length),
    );
  }
}
