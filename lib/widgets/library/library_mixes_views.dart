import 'package:flutter/material.dart';
import '../../services/music_player_manager.dart';
import '../../screens/playlist_detail_screen.dart';

/// Sliver content for the 'Albums' category in LibraryTab.
class LibraryAlbumsSliverView extends StatelessWidget {
  final MusicPlayerManager manager;
  final bool isDark;
  final Color cardColor;
  final Color cardBorder;

  const LibraryAlbumsSliverView({
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
        final pl = manager.genreMixes[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                pl.coverUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              pl.title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              pl.description,
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlist: pl),
                ),
              );
            },
          ),
        );
      }, childCount: manager.genreMixes.length),
    );
  }
}

/// Sliver content for the 'Artists' category in LibraryTab.
class LibraryArtistsSliverView extends StatelessWidget {
  final MusicPlayerManager manager;
  final bool isDark;
  final Color cardColor;
  final Color cardBorder;

  const LibraryArtistsSliverView({
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
        final artistMix = manager.artistMixes[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(artistMix.coverUrl),
            ),
            title: Text(
              artistMix.title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              artistMix.description,
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlist: artistMix),
                ),
              );
            },
          ),
        );
      }, childCount: manager.artistMixes.length),
    );
  }
}
