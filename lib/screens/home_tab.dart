import 'package:flutter/material.dart';
import '../services/music_player_manager.dart';
import '../services/theme_service.dart';
import '../services/download_service.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_top_header.dart';
import '../widgets/app_cached_image.dart';
import 'playlist_detail_screen.dart';
import 'new_releases_screen.dart';
import '../widgets/home/continue_playing_section.dart';
import '../widgets/home/language_section.dart';
import '../widgets/home/mood_mixes_section.dart';
import 'artists_screen.dart';
import 'downloaded_songs_screen.dart';

import '../data/music_repository.dart';
import '../services/music_api_service.dart';
import '../services/database_service.dart';
import '../models/playlist.dart';
import 'friends_screen.dart';

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

  Future<void> _playArtist(
    BuildContext context,
    Map<String, String> artist,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading top tracks for ${artist['name']}... 🎵'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    final songs = await MusicApiService.searchLiveSongs(
      artist['query'] ?? '${artist['name']} hits',
      limit: 25,
    );
    if (songs.isNotEmpty && context.mounted) {
      final playlist = Playlist(
        id: artist['id'] ?? 'art_${artist['name']}',
        title: '${artist['name']} Essentials',
        description: '${artist['role']} • ${artist['listeners']}',
        coverUrl: artist['imageUrl'] ?? '',
        songIds: songs.map((s) => s.id).toList(),
        songs: songs,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlist: playlist),
        ),
      );
    }
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onArrowTap,
  }) {
    final textColor = AppThemeManager.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 14, 14),
      child: InkWell(
        onTap: onArrowTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: textColor,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final downloadService = DownloadService();
    final downloadedSongs = downloadService.downloadedSongs;

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        final playlists = manager.playlists;
        final newReleases = manager.newReleases;
        final isOffline =
            manager.onlineTrending.isEmpty && !manager.isLoadingTrending;

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

              // Offline Banner if offline or if downloads are available
              if (isOffline || downloadedSongs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOffline
                            ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                            : [
                                const Color(0xFF064E3B),
                                const Color(0xFF0F172A),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isOffline
                            ? const Color(0xFF6366F1).withOpacity(0.4)
                            : const Color(0xFF10B981).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                (isOffline
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFF10B981))
                                    .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOffline
                                ? Icons.flight_takeoff_rounded
                                : Icons.offline_pin_rounded,
                            color: isOffline
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF34D399),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOffline
                                    ? 'Offline Mode Active ✈️'
                                    : 'Downloaded Songs Ready ⚡',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${downloadedSongs.length} downloaded tracks ready for offline listening without internet.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOffline
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DownloadedSongsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Open',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                            'Discover Music',
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
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
                                      : (AppThemeManager.instance.isDarkMode
                                            ? Colors.white12
                                            : const Color(0xFFE2E8F0)),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(
                                    0xFF818CF8,
                                  ).withOpacity(0.4),
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

              // CONTINUE PLAYING (recent + currently loaded song)
              const SliverToBoxAdapter(child: ContinuePlayingSection()),

              // SONGS BY LANGUAGE (Hindi, English, Punjabi, Bhojpuri, Tamil...)
              const SliverToBoxAdapter(child: LanguageSection()),

              // MOOD MIXES (replaces Top 50)
              const SliverToBoxAdapter(child: MoodMixesSection()),

              if (newReleases.isNotEmpty) ...[
              // 3. NEW RELEASES: Dedicated Carousel & Navigation to NewReleasesScreen
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'New releases',
                  onArrowTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NewReleasesScreen(),
                      ),
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
                    itemCount: newReleases.length,
                    itemBuilder: (context, index) {
                      final song = newReleases[index];
                      final isCurrent = manager.currentSong?.id == song.id;

                      return GestureDetector(
                        onTap: () {
                          if (isCurrent) {
                            manager.togglePlay();
                          } else {
                            manager.playSong(song, newQueue: newReleases);
                          }
                        },
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
                                    AppCachedImage(
                                      imageUrl: song.coverUrl,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
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
                                            color: Colors.black.withOpacity(
                                              0.75,
                                            ),
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
                                  color: isCurrent
                                      ? const Color(0xFF818CF8)
                                      : AppThemeManager.textPrimary(context),
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
              ],

              // 4. POPULAR ARTISTS & SINGERS SECTION
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'Popular Artists & Singers',
                  onArrowTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ArtistsScreen()),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: MusicRepository.popularArtists.length,
                    itemBuilder: (context, index) {
                      final artist = MusicRepository.popularArtists[index];
                      return GestureDetector(
                        onTap: () => _playArtist(context, artist),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF4B2B),
                                      Color(0xFFFF416C),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF4B2B,
                                      ).withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: AppCachedImage(
                                    imageUrl: artist['imageUrl'] ?? '',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    fallbackIcon: Icons.person_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                artist['name']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppThemeManager.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                artist['role']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
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

              // 5. FRIENDS LISTENING LIVE SECTION
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'Friends Listening Now',
                  onArrowTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FriendsScreen()),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final db = DatabaseService.instance;
                    final listeningCount = db.friendsListening.length;
                    final hasActive = listeningCount > 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              Theme.of(context).brightness == Brightness.dark
                              ? [
                                  const Color(0xFF1A1528),
                                  const Color(0xFF101018),
                                ]
                              : [const Color(0xFFF1F5F9), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.headphones_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      hasActive
                                          ? '$listeningCount Friend${listeningCount > 1 ? 's' : ''} Streaming'
                                          : 'Live Jam & Blend Sessions',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      hasActive ? '🟢 Live' : '⚪ Standby',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: hasActive
                                            ? const Color(0xFF10B981)
                                            : Colors.white54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hasActive
                                      ? 'Tap to join synchronized live session'
                                      : 'Start a shared Jam room or invite friends to listen together',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppThemeManager.textSecondary(
                                      context,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FriendsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              hasActive ? 'Join' : 'Open Jam',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Bottom Footer: Download App, Terms, Privacy Policy & Made with Love by Kranti
              const SliverToBoxAdapter(child: AppFooter()),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }
}
