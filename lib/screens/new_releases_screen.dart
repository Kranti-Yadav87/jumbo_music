import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/track_options_sheet.dart';

class NewReleasesScreen extends StatelessWidget {
  const NewReleasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final newReleases = manager.newReleases;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: const Color(0xFF0D0D12),
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'New Releases',
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
                          content: Text('New Releases playlist link copied!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Hero Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -15,
                          bottom: -15,
                          child: Icon(
                            Icons.album_rounded,
                            size: 150,
                            color: Colors.white.withOpacity(0.15),
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
                                  '🔥 Fresh Drops',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Latest Singles & Albums',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${newReleases.length} Tracks • Updated daily with studio audio',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons: Play All & Shuffle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: const Text(
                            'Play All',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            if (newReleases.isNotEmpty) {
                              manager.playSong(newReleases.first, newQueue: newReleases);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.shuffle_rounded, size: 20),
                          label: const Text(
                            'Shuffle',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            if (newReleases.isNotEmpty) {
                              final shuffled = List<Song>.from(newReleases)..shuffle();
                              manager.playSong(shuffled.first, newQueue: shuffled);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 12),
              ),

              // Song List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = newReleases[index];
                    final isCurrent = manager.currentSong?.id == song.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF6366F1).withOpacity(0.12)
                            : const Color(0xFF13131A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF6366F1).withOpacity(0.4)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        onTap: () => manager.playSong(song, newQueue: newReleases),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                song.coverUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: const Color(0xFF1E1E24),
                                  child: const Icon(Icons.music_note_rounded, color: Colors.white38),
                                ),
                              ),
                              if (isCurrent && manager.isPlaying)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.55),
                                    child: const Center(
                                      child: EqualizerBars(
                                        isPlaying: true,
                                        color: Color(0xFF818CF8),
                                        height: 16,
                                        barCount: 3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? const Color(0xFF818CF8) : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.album.isNotEmpty ? song.album : 'Single'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                manager.isFavorite(song.id)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: manager.isFavorite(song.id)
                                    ? const Color(0xFFF43F5E)
                                    : Colors.white38,
                                size: 20,
                              ),
                              onPressed: () => manager.toggleFavorite(song.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => TrackOptionsSheet(song: song),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: newReleases.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 140),
              ),
            ],
          ),
        );
      },
    );
  }
}
