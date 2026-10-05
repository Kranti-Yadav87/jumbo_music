import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../services/music_player_manager.dart';
import '../../services/download_service.dart';
import '../../screens/downloaded_songs_screen.dart';
import '../../screens/cached_offline_screen.dart';
import '../../screens/playlist_detail_screen.dart';
import '../../screens/history_tab.dart';
import 'library_square_card.dart';

/// Sliver content for the 'Playlists' category: 2x2 quick access cards and custom playlists.
class LibraryPlaylistsSliverView extends StatelessWidget {
  final MusicPlayerManager manager;
  final DownloadService downloadService;
  final bool isDark;
  final Color cardColor;
  final Color cardBorder;

  const LibraryPlaylistsSliverView({
    super.key,
    required this.manager,
    required this.downloadService,
    required this.isDark,
    required this.cardColor,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final favSongs = manager.favoriteSongs;
    final historySongs = manager.recentlyPlayed;
    final downloadedCount = downloadService.totalDownloadedCount;
    final cachedCount = historySongs.length + downloadedCount;

    return SliverMainAxisGroup(
      slivers: [
        // 2x2 Grid Square Cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: [
              LibrarySquareCard(
                icon: Icons.history_rounded,
                title: 'Recently Played',
                countText: '${historySongs.length} tracks',
                cardBg: cardColor,
                cardBorder: cardBorder,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryTab()),
                  );
                },
              ),
              LibrarySquareCard(
                icon: Icons.favorite_rounded,
                title: 'Favorites',
                countText: '${favSongs.length} songs',
                cardBg: cardColor,
                cardBorder: cardBorder,
                isDark: isDark,
                onTap: () {
                  final favPlaylist = Playlist(
                    id: 'favs',
                    title: 'Liked Songs',
                    description: 'Your favorite collection',
                    coverUrl: favSongs.isNotEmpty
                        ? favSongs.first.coverUrl
                        : 'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
                    songIds: manager.favoriteIds.toList(),
                    songs: favSongs,
                    type: PlaylistType.favorites,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlaylistDetailScreen(playlist: favPlaylist),
                    ),
                  );
                },
              ),
              LibrarySquareCard(
                icon: Icons.flight_rounded,
                title: 'Cached/Offline',
                countText: '$cachedCount offline streams',
                cardBg: cardColor,
                cardBorder: cardBorder,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CachedOfflineScreen(),
                    ),
                  );
                },
              ),
              LibrarySquareCard(
                icon: Icons.download_rounded,
                title: 'Downloads',
                countText: '$downloadedCount 320kbps songs',
                cardBg: cardColor,
                cardBorder: cardBorder,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DownloadedSongsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(
              'MY PLAYLISTS & MIXES',
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final pl = manager.playlists[index];
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
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFF1E293B),
                      child: const Icon(
                        Icons.queue_music,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  pl.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                subtitle: Text(
                  '${pl.songs.length} songs • ${pl.description}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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
          }, childCount: manager.playlists.length),
        ),
      ],
    );
  }
}
