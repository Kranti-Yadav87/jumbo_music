import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/playlist.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import 'downloaded_songs_screen.dart';
import 'cached_offline_screen.dart';
import 'playlist_detail_screen.dart';
import 'history_tab.dart';
import 'search_tab.dart';
import '../widgets/track_options_sheet.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _selectedCategory = 'Playlists';
  bool _isAscending = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Playlists',
    'Songs',
    'Albums',
    'Artists',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131D31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Text('Library & Offline Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Playlists: Create and organize custom and shared blends.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 8),
            Text('• Recently Played: Track all previously listened tracks.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 8),
            Text('• Favorites: One-tap access to all liked songs.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 8),
            Text('• Cached/Offline: Plays stored stream cache without internet.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 8),
            Text('• Downloads: 320 kbps offline master tracks saved permanently.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'Listen to ad-free HD music and download songs offline on Jumbo Music!'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App share link copied to clipboard! ✨'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MusicPlayerManager manager) {
    final titleController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131D31) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'New Playlist',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: titleController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Playlist Name',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  manager.createPlaylist(title, description: 'Custom Collection');
                  Navigator.pop(context);
                }
              },
              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final downloadService = DownloadService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF081220) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E2D4A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2B3E63) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        final favSongs = manager.favoriteSongs;
        final historySongs = manager.recentlyPlayed;
        final downloadedCount = downloadService.totalDownloadedCount;
        final cachedCount = historySongs.length + downloadedCount;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top App Bar (Chill Ratna / Jumbo Brand Logo + Help ? + Share icon <) - Screenshot 1
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                    child: Row(
                      children: [
                        // App Logo Glyph
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF081220),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // App Brand Title
                        Text(
                          'Jumbo Music',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        // Help Icon (?)
                        IconButton(
                          icon: Icon(
                            Icons.help_outline_rounded,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            size: 22,
                          ),
                          tooltip: 'Help & Info',
                          onPressed: () => _showHelpDialog(context),
                        ),
                        // Share Icon (<)
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            size: 20,
                          ),
                          tooltip: 'Share App',
                          onPressed: () => _shareApp(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. "Library" Title & Round Plus (+) Button - Screenshot 1
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Library',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        // Circular Plus Button (+)
                        GestureDetector(
                          onTap: () => _showCreatePlaylistDialog(context, manager),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF263756) : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Category Tabs: Playlists (with underline), Songs, Albums, Artists - Screenshot 1
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                        : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                              // Active White Underline Indicator
                              Container(
                                height: 2.5,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? (isDark ? Colors.white : const Color(0xFF0EA5E9)) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 4. Sub-bar: "4 items AZ" ↓ 📖 🔍 - Screenshot 1
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedCategory == "Playlists" ? 4 : manager.allSongs.length} items',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // AZ sort badge
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAscending = !_isAscending;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                _isAscending ? 'AZ' : 'ZA',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                              Icon(
                                _isAscending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                size: 14,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // View mode book icon (📖)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        // Search icon (🔍)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchTab()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // 5. THE 4 BIG SQUARE CARDS (2x2 GRID) - EXACT MATCH TO SCREENSHOT 1
                if (_selectedCategory == 'Playlists') ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                      children: [
                        // Card 1: Recently Played (Clock / History Icon)
                        _buildBigSquareCard(
                          context,
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

                        // Card 2: Favorites (Solid White Heart Icon)
                        _buildBigSquareCard(
                          context,
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
                              MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: favPlaylist)),
                            );
                          },
                        ),

                        // Card 3: Cached/Offline (Airplane Icon ✈️)
                        _buildBigSquareCard(
                          context,
                          icon: Icons.flight_rounded,
                          title: 'Cached/Offline',
                          countText: '$cachedCount offline streams',
                          cardBg: cardColor,
                          cardBorder: cardBorder,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CachedOfflineScreen()),
                            );
                          },
                        ),

                        // Card 4: Downloads (Download Arrow Icon ⬇️)
                        _buildBigSquareCard(
                          context,
                          icon: Icons.download_rounded,
                          title: 'Downloads',
                          countText: '$downloadedCount 320kbps songs',
                          cardBg: cardColor,
                          cardBorder: cardBorder,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DownloadedSongsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Playlists List below the 4 cards
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                                  child: const Icon(Icons.queue_music, color: Colors.white54),
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
                      },
                      childCount: manager.playlists.length,
                    ),
                  ),
                ] else if (_selectedCategory == 'Songs') ...[
                  // Songs List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                song.coverUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent ? const Color(0xFF38BDF8) : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
                            onTap: () => manager.playSong(song, newQueue: manager.allSongs),
                          ),
                        );
                      },
                      childCount: manager.allSongs.length,
                    ),
                  ),
                ] else if (_selectedCategory == 'Albums') ...[
                  // Albums / Mixes List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                              child: Image.network(pl.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
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
                                MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: pl)),
                              );
                            },
                          ),
                        );
                      },
                      childCount: manager.genreMixes.length,
                    ),
                  ),
                ] else if (_selectedCategory == 'Artists') ...[
                  // Artists List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                                MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: artistMix)),
                              );
                            },
                          ),
                        );
                      },
                      childCount: manager.artistMixes.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper Widget for the 4 Big Square Cards matching Screenshot 1
  Widget _buildBigSquareCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String countText,
    required Color cardBg,
    required Color cardBorder,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Center Big Icon
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 14),
            // Title (Recently Played, Favorites, Cached/Offline, Downloads)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              countText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
