import 'package:flutter/material.dart';
import '../services/music_player_manager.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/track_options_sheet.dart';

class Top50Screen extends StatelessWidget {
  const Top50Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final top50 = manager.top50Songs;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top App Bar
              SliverAppBar(
                backgroundColor: const Color(0xFF0D0D12),
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Top 50 Chartbusters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white70),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Top 50 Chartbusters playlist link copied!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Hero Banner with Artwork & Play All / Shuffle Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        height: 190,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE11D48), Color(0xFF9333EA), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                size: 160,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '🔥 OFFICIAL RANKINGS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Top 50 Chartbusters',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${top50.length} songs • India & Global Trending • 320 kbps Studio',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons: Play All & Shuffle
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5A5A5),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text(
                                'Play All',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                if (top50.isNotEmpty) {
                                  manager.playPlaylist(top50, initialIndex: 0);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.shuffle_rounded, size: 20),
                              label: const Text(
                                'Shuffle',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (top50.isNotEmpty) {
                                  if (!manager.isShuffle) {
                                    manager.toggleShuffle();
                                  }
                                  manager.playPlaylist(top50, initialIndex: 0);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Top 50 Ranked Songs List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = top50[index];
                    final isCurrent = manager.currentSong?.id == song.id;
                    final isPlaying = isCurrent && manager.isPlaying;
                    final isFav = manager.isFavorite(song.id);

                    // Rank styling
                    Color rankColor = Colors.white54;
                    if (index == 0) rankColor = const Color(0xFFF59E0B); // Gold #1
                    if (index == 1) rankColor = const Color(0xFF94A3B8); // Silver #2
                    if (index == 2) rankColor = const Color(0xFFB45309); // Bronze #3

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF1E1C24) : const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFFE5A5A5).withOpacity(0.5)
                              : Colors.white.withOpacity(0.04),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Rank Number
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${index + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: rankColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Artwork with live equalizer when playing
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    song.coverUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: const Color(0xFF2C2C2E),
                                      child: const Icon(Icons.music_note, color: Colors.white30),
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
                                    child: const Center(
                                      child: EqualizerBars(
                                        isPlaying: true,
                                        color: Color(0xFFE5A5A5),
                                        height: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? const Color(0xFFE5A5A5) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.formattedDuration}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Heart favorite
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? const Color(0xFFE5A5A5) : Colors.white54,
                                size: 20,
                              ),
                              onPressed: () => manager.toggleFavorite(song.id),
                            ),
                            // Play/Pause icon
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                color: isCurrent ? const Color(0xFFE5A5A5) : Colors.white70,
                                size: 28,
                              ),
                              onPressed: () {
                                if (isCurrent) {
                                  manager.togglePlay();
                                } else {
                                  manager.playSong(song, newQueue: top50);
                                }
                              },
                            ),
                            // 3-dots menu for download & options
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                              onPressed: () => TrackOptionsSheet.show(context, song),
                            ),
                          ],
                        ),
                        onTap: () {
                          manager.playSong(song, newQueue: top50);
                        },
                      ),
                    );
                  },
                  childCount: top50.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        );
      },
    );
  }
}
