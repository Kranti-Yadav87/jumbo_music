import 'package:flutter/material.dart';
import '../services/music_player_manager.dart';
import '../services/theme_service.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_top_header.dart';
import 'playlist_detail_screen.dart';
import 'top_50_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeTab({super.key, this.onProfileTap});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, VoidCallback? onArrowTap}) {
    final textColor = AppThemeManager.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 14, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          if (onArrowTap != null)
            IconButton(
              icon: Icon(Icons.arrow_forward_rounded, color: textColor, size: 22),
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Unified App Top Header (Search, Notification, Setting, Profile Avatar)
              SliverToBoxAdapter(
                child: AppTopHeader(
                  title: 'Jumbo Music',
                  onProfileTap: widget.onProfileTap,
                ),
              ),

              // 2. Greeting & Quick Filter / Autoplay Pill Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemeManager.textSecondary(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Featured & Trending',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: AppThemeManager.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Autoplay quick toggle badge
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => manager.toggleAutoplay(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: manager.autoplay
                                    ? const Color(0xFFFF5E3A).withOpacity(0.15)
                                    : (AppThemeManager.instance.isDarkMode
                                        ? Colors.white.withOpacity(0.06)
                                        : Colors.black.withOpacity(0.04)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: manager.autoplay
                                      ? const Color(0xFFFF5E3A).withOpacity(0.5)
                                      : (AppThemeManager.instance.isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.all_inclusive_rounded,
                                    size: 14,
                                    color: manager.autoplay
                                        ? const Color(0xFFFF5E3A)
                                        : AppThemeManager.textMuted(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    manager.autoplay ? 'Radio' : 'Off',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: manager.autoplay
                                          ? const Color(0xFFFF5E3A)
                                          : AppThemeManager.textMuted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (manager.isSleepTimerActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF818CF8).withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.bedtime_rounded,
                                    size: 11,
                                    color: Color(0xFF818CF8),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    manager.formattedSleepTime,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF818CF8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppThemeManager.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                playlist.description,
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
                                  color: isCurrent ? const Color(0xFF818CF8) : AppThemeManager.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppThemeManager.textSecondary(context),
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
                                  color: isCurrent ? const Color(0xFF818CF8) : AppThemeManager.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppThemeManager.textSecondary(context),
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

              // Bottom Footer: Download App, Terms, Privacy Policy & Made with Love by Kranti
              const SliverToBoxAdapter(
                child: AppFooter(),
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
