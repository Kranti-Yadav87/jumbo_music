import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../services/music_player_manager.dart';
import '../../screens/history_tab.dart';
import '../../screens/playlist_detail_screen.dart';
import 'profile_dialogs.dart';

/// Single statistic card widget in profile screen.
class ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String count;
  final String label;
  final VoidCallback onTap;

  const ProfileStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161622) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of 3 metric / stats cards in ProfileScreen (Liked Songs, Playlists, Hours Played).
class ProfileStatsRow extends StatelessWidget {
  final MusicPlayerManager manager;

  const ProfileStatsRow({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final likedCount = manager.favoriteSongs.length;
    final playlistCount = manager.playlists.length;
    final historyCount = manager.recentlyPlayed.length;
    final hoursPlayed = historyCount > 0
        ? '${(historyCount * 0.4).toStringAsFixed(1)}h'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Liked Songs
          Expanded(
            child: ProfileStatCard(
              icon: Icons.favorite_border_rounded,
              iconColor: const Color(0xFFFF5E7E),
              count: '$likedCount',
              label: 'Liked Songs',
              onTap: () {
                final favPlaylist = Playlist(
                  id: 'favs',
                  title: 'Liked Songs',
                  description: 'Your favorite collection',
                  coverUrl: manager.favoriteSongs.isNotEmpty
                      ? manager.favoriteSongs.first.coverUrl
                      : 'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
                  songIds: manager.favoriteIds.toList(),
                  songs: manager.favoriteSongs,
                  type: PlaylistType.favorites,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(playlist: favPlaylist),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),

          // 2. Playlists
          Expanded(
            child: ProfileStatCard(
              icon: Icons.music_note_rounded,
              iconColor: const Color(0xFFA855F7),
              count: '$playlistCount',
              label: 'Playlists',
              onTap: () => showProfilePlaylistsSheet(context, manager),
            ),
          ),
          const SizedBox(width: 10),

          // 3. Hours Played
          Expanded(
            child: ProfileStatCard(
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFF38BDF8),
              count: hoursPlayed,
              label: 'Hours Played',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryTab()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
