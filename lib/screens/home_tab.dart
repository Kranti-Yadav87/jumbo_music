import 'package:flutter/material.dart';
import '../models/song.dart';
import '../data/music_repository.dart';
import '../services/music_player_manager.dart';
import '../widgets/song_tile.dart';
import '../widgets/equalizer_bars.dart';
import 'playlist_detail_screen.dart';
import 'privacy_security_screen.dart';
import 'top_50_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedGenre = 'All';

  final List<String> _genres = [
    'All',
    'Bollywood',
    'Romantic',
    'Punjabi',
    'Lo-Fi',
    'Acoustic',
    'EDM',
    'Chill',
    'Pop',
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final allSongs = manager.allSongs;
        final filteredSongs = _selectedGenre == 'All'
            ? allSongs
            : allSongs.where((s) {
                final q = _selectedGenre.toLowerCase();
                return s.genre.toLowerCase().contains(q) ||
                    s.title.toLowerCase().contains(q) ||
                    s.artist.toLowerCase().contains(q);
              }).toList();

        final featuredSong = manager.currentSong ?? (allSongs.isNotEmpty ? allSongs.first : null);
        final quickPicks = manager.recentlyPlayed.isNotEmpty
            ? manager.recentlyPlayed
            : allSongs.take(8).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                            const SizedBox(width: 4),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero Feature Card (Chill Ratna High Quality Banner)
              if (featuredSong != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      image: DecorationImage(
                        image: NetworkImage(featuredSong.coverUrl),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.92),
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (manager.isPlaying && manager.currentSong?.id == featuredSong.id)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: EqualizerBars(isPlaying: true, color: Colors.white, height: 10, barCount: 3),
                                      ),
                                    Text(
                                      manager.isPlaying && manager.currentSong?.id == featuredSong.id
                                          ? 'NOW PLAYING LIVE'
                                          : 'TRENDING HIT',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '320 KBPS STUDIO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            featuredSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${featuredSong.artist} • ${featuredSong.album}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: Icon(
                                  manager.isPlaying && manager.currentSong?.id == featuredSong.id
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 22,
                                ),
                                label: Text(
                                  manager.isPlaying && manager.currentSong?.id == featuredSong.id
                                      ? 'Pause'
                                      : 'Play Stream',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  if (manager.currentSong?.id == featuredSong.id) {
                                    manager.togglePlay();
                                  } else {
                                    manager.playSong(featuredSong);
                                  }
                                },
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: Icon(
                                  manager.isFavorite(featuredSong.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: manager.isFavorite(featuredSong.id)
                                      ? const Color(0xFFEF4444)
                                      : Colors.white70,
                                ),
                                onPressed: () => manager.toggleFavorite(featuredSong.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Genre Filter Pills
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _genres.length,
                    itemBuilder: (context, index) {
                      final genre = _genres[index];
                      final isSelected = genre == _selectedGenre;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(genre),
                          selected: isSelected,
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: Colors.white.withOpacity(0.06),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF818CF8)
                                  : Colors.white10,
                            ),
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedGenre = genre;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Quick Picks Horizontal Row (Recently Played or Jump Back In)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        manager.recentlyPlayed.isNotEmpty
                            ? 'Listen Again & Quick Picks'
                            : 'Recommended For You',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.bolt_rounded, color: Color(0xFF818CF8), size: 20),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 145,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: quickPicks.length,
                    itemBuilder: (context, index) {
                      final song = quickPicks[index];
                      final isCurrent = manager.currentSong?.id == song.id;

                      return GestureDetector(
                        onTap: () => manager.playSong(song),
                        child: Container(
                          width: 115,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      song.coverUrl,
                                      width: 115,
                                      height: 95,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 115,
                                        height: 95,
                                        color: Colors.white10,
                                        child: const Icon(Icons.music_note, color: Colors.white54),
                                      ),
                                    ),
                                    if (isCurrent && manager.isPlaying)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.5),
                                          child: Center(
                                            child: EqualizerBars(isPlaying: true, color: const Color(0xFF818CF8), height: 18),
                                          ),
                                        ),
                                      )
                                    else
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? const Color(0xFF818CF8) : Colors.white,
                                ),
                              ),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
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

              // Smart Mixes & Stations Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Featured Playlists & Stations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${manager.playlists.length} mixes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: manager.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = manager.playlists[index];
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
                                      playlist.coverUrl,
                                      width: 140,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 140,
                                        height: 110,
                                        color: const Color(0xFF1E1B4B),
                                        child: const Icon(
                                          Icons.queue_music,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                playlist.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                playlist.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
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

              // 1. Dedicated Top 50 Chartbusters Section (If 'All' is selected)
              if (_selectedGenre == 'All') ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48).withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFF43F5E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Top 50 Chartbusters',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${manager.top50Songs.length} songs • Official Rankings',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFE5A5A5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          icon: const Text('See All 50', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          label: const Icon(Icons.arrow_forward_rounded, size: 16),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Top50Screen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Top 8 preview list with rank badges
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = manager.top50Songs[index];
                      return SongTile(
                        song: song,
                        index: index + 1,
                        playlistContext: manager.top50Songs,
                      );
                    },
                    childCount: manager.top50Songs.length > 8 ? 8 : manager.top50Songs.length,
                  ),
                ),

                // Button to open full Top 50 screen
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE5A5A5),
                        side: BorderSide(color: const Color(0xFFE5A5A5).withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
                      label: const Text(
                        'View Full Top 50 Chartbusters Rankings →',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Top50Screen()),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 2. Separate Music Catalog / Filtered Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedGenre == 'All' ? Icons.library_music_rounded : Icons.category_rounded,
                            size: 18,
                            color: const Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedGenre == 'All'
                                ? 'All Tracks Catalog'
                                : '$_selectedGenre Collection',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${filteredSongs.length} tracks',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filtered songs list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = filteredSongs[index];
                    return SongTile(
                      song: song,
                      index: index + 1,
                      playlistContext: filteredSongs,
                    );
                  },
                  childCount: filteredSongs.length,
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
