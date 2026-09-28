import 'package:flutter/material.dart';
import '../models/song.dart';
import '../data/music_repository.dart';
import '../services/music_player_manager.dart';
import '../widgets/song_tile.dart';
import '../widgets/equalizer_bars.dart';
import 'playlist_detail_screen.dart';
import 'privacy_security_screen.dart';
import 'top_50_screen.dart';
import 'search_tab.dart';
import '../widgets/install_app_card.dart';
import '../widgets/download_app_dialog.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final List<String> _moodAndGenres = [
    'Classical',
    'Desi hip-hop',
    'Country & Americana',
    'Devotional',
    'Dance & electronic',
    'Family',
    'Decades',
    'Folk & acoustic',
    'Bollywood',
    'Lo-Fi & Chill',
    'Pop & Chart',
    'Romantic',
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  void _showGenreBottomSheet(BuildContext context, String genre, MusicPlayerManager manager) {
    final genreSongs = manager.allSongs.where((s) {
      final q = genre.toLowerCase();
      return s.genre.toLowerCase().contains(q) ||
          s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121217),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF818CF8), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              genre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${genreSongs.length} tracks available',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      if (genreSongs.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Play Radio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            manager.playSong(genreSongs.first, newQueue: genreSongs);
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: genreSongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.queue_music_rounded, size: 48, color: Colors.white24),
                              const SizedBox(height: 12),
                              Text('No songs currently tagged in $genre',
                                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  manager.toggleAutoplay();
                                },
                                child: const Text('Start Smart Radio'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: genreSongs.length,
                          itemBuilder: (context, index) {
                            final song = genreSongs[index];
                            return SongTile(
                              song: song,
                              index: index + 1,
                              playlistContext: genreSongs,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, VoidCallback? onArrowTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 14, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          if (onArrowTap != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
              onPressed: onArrowTap,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final playlists = manager.playlists;
        final top50 = manager.top50Songs;
        final newReleases = manager.newReleases;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Header with Greeting, Brand & Sleep Timer
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text(
                                  'JUMBO MUSIC',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF818CF8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Autoplay quick toggle badge
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => manager.toggleAutoplay(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: manager.autoplay
                                      ? const Color(0xFF10B981).withOpacity(0.15)
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: manager.autoplay
                                        ? const Color(0xFF10B981).withOpacity(0.4)
                                        : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.all_inclusive_rounded,
                                      size: 14,
                                      color: manager.autoplay
                                          ? const Color(0xFF10B981)
                                          : Colors.white38,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      manager.autoplay ? 'Radio ON' : 'Radio OFF',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: manager.autoplay
                                            ? const Color(0xFF10B981)
                                            : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (manager.isSleepTimerActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF818CF8).withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.bedtime_rounded,
                                      size: 12,
                                      color: Color(0xFF818CF8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      manager.formattedSleepTime,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF818CF8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            // Download / Install App Button
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.file_download_outlined, color: Color(0xFF818CF8), size: 24),
                              tooltip: 'Download / Install App',
                              onPressed: () => showDownloadAppDialog(context),
                            ),
                            const SizedBox(width: 10),
                            // Data Privacy & Security Shield Button
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
                              tooltip: 'Data Privacy & Security',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            // Live Search Button
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                              tooltip: 'Search Songs & Artists',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SearchTab()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // REC MedAssist-style Install App Card
              const SliverToBoxAdapter(
                child: InstallAppCard(
                  margin: EdgeInsets.fromLTRB(18, 4, 18, 12),
                ),
              ),

              // 1. TOP CAROUSEL: Mixes & Featured Playlists (90s Chill, '90s Indian Pop, Tamil, etc.)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 215,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(playlist: playlist),
                            ),
                          );
                        },
                        child: Container(
                          width: 145,
                          margin: const EdgeInsets.only(right: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      playlist.coverUrl,
                                      width: 145,
                                      height: 145,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 145,
                                        height: 145,
                                        color: const Color(0xFF18181B),
                                        child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 40),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.75),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                playlist.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                playlist.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. TOP 50 CHARTBUSTERS: Dedicated Clean Carousel with Arrow -> Full Rankings Screen
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'Top 50 Chartbusters',
                  onArrowTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Top50Screen()),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 215,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: top50.length > 15 ? 15 : top50.length,
                    itemBuilder: (context, index) {
                      final song = top50[index];
                      final rank = index + 1;
                      final isCurrent = manager.currentSong?.id == song.id;

                      return GestureDetector(
                        onTap: () => manager.playSong(song, newQueue: top50),
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
                                    Image.network(
                                      song.coverUrl,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 140,
                                        height: 140,
                                        color: const Color(0xFF18181B),
                                        child: const Icon(Icons.music_note_rounded, color: Colors.white38),
                                      ),
                                    ),
                                    // Rank Badge
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          gradient: rank == 1
                                              ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                                              : rank == 2
                                                  ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                                                  : rank == 3
                                                      ? const LinearGradient(colors: [Color(0xFFB45309), Color(0xFF78350F)])
                                                      : LinearGradient(colors: [
                                                          const Color(0xFF1E1E24).withOpacity(0.9),
                                                          const Color(0xFF0F0F14).withOpacity(0.9),
                                                        ]),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.4),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          rank == 1 ? '👑 #1' : '#$rank',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Play / Equalizer Overlay
                                    if (isCurrent && manager.isPlaying)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.55),
                                          child: Center(
                                            child: EqualizerBars(
                                              isPlaying: true,
                                              color: const Color(0xFF818CF8),
                                              height: 22,
                                              barCount: 4,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.75),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 20,
                                            color: Colors.white,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? const Color(0xFF818CF8) : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3. NEW RELEASES: Exact Match to Screenshot (Mero Mann, AUJLA SZN 1, Ghostface, etc.)
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'New releases',
                  onArrowTap: () {
                    if (newReleases.isNotEmpty) {
                      manager.playSong(newReleases.first, newQueue: newReleases);
                    }
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 215,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: newReleases.length,
                    itemBuilder: (context, index) {
                      final song = newReleases[index];
                      final isCurrent = manager.currentSong?.id == song.id;

                      return GestureDetector(
                        onTap: () => manager.playSong(song, newQueue: newReleases),
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
                                    Image.network(
                                      song.coverUrl,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 140,
                                        height: 140,
                                        color: const Color(0xFF18181B),
                                        child: const Icon(Icons.album_rounded, color: Colors.white38),
                                      ),
                                    ),
                                    if (isCurrent && manager.isPlaying)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.55),
                                          child: Center(
                                            child: EqualizerBars(
                                              isPlaying: true,
                                              color: const Color(0xFF818CF8),
                                              height: 22,
                                              barCount: 4,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.75),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 20,
                                            color: Colors.white,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? const Color(0xFF818CF8) : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. MOOD AND GENRES: Exact 2-Column Dark Category Grid Matching Screenshot
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'Mood and Genres',
                  onArrowTap: () {
                    _showGenreBottomSheet(context, _moodAndGenres.first, manager);
                  },
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 52,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final genre = _moodAndGenres[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showGenreBottomSheet(context, genre, manager),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                genre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _moodAndGenres.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        );
      },
    );
  }
}
