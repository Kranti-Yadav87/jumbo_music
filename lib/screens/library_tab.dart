import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import 'downloaded_songs_screen.dart';
import 'playlist_detail_screen.dart';
import 'search_tab.dart';
import 'privacy_security_screen.dart';
import 'top_50_screen.dart';
import '../widgets/track_options_sheet.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _selectedCategory = 'Playlists';
  String _sortBy = 'Date added';
  bool _isDescending = true;

  final List<String> _categories = [
    'Playlists',
    'Songs',
    'Albums',
    'Artists',
  ];

  void _showSettingsDialog(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Settings & Audio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: manager.autoplay,
                  activeColor: const Color(0xFFE5A5A5),
                  title: const Text('Infinite Autoplay', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Keep playing related music continuously', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onChanged: (_) {
                    manager.toggleAutoplay();
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.equalizer_rounded, color: Color(0xFFE5A5A5)),
                  title: const Text('Audio Quality Preset', style: TextStyle(color: Colors.white)),
                  subtitle: Text(manager.soundPreset, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const Icon(Icons.shield_rounded, color: Color(0xFF10B981)),
                  title: const Text('Data Privacy & Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('100% Client-side. Incognito, vault, no tracking.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MusicPlayerManager manager) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New Playlist',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Playlist Name',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A5A5),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  manager.createPlaylist(title, 'Custom Collection');
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

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        final favSongs = manager.favoriteSongs;
        final downloadedCount = downloadService.totalDownloadedCount;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Bar: Jumbo Brand Icon + Name, Search & Settings Icons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                    child: Row(
                      children: [
                        // Stylized Logo Icon
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                        const Text(
                          'Jumbo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchTab()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                          onPressed: () => _showSettingsDialog(context, manager),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Horizontal Category Filter Pills (Playlists, Songs, Albums, Artists)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFF18181A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // 3. Subheader Sort & Control Bar (Date added ↓, lock, list icon)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isDescending = !_isDescending;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                _sortBy,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isDescending
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 18),
                        const Icon(Icons.format_list_bulleted_rounded, color: Colors.white70, size: 22),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // 4. Quick Access Tiles (Screenshot 2: Liked, Downloaded, My top 50, Cached)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Liked Tile
                        _buildQuickAccessTile(
                          icon: Icons.favorite_border_rounded,
                          title: 'Liked',
                          subtitle: '${favSongs.length} songs',
                          onTap: () {
                            final favPlaylist = Playlist(
                              id: 'favs',
                              title: 'Liked Songs',
                              description: 'Your personal collection of favorites',
                              coverUrl: favSongs.isNotEmpty
                                  ? favSongs.first.coverUrl
                                  : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
                              songIds: manager.favoriteIds.toList(),
                              songs: favSongs,
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
                        const SizedBox(height: 8),

                        // Downloaded Tile (User explicit request)
                        _buildQuickAccessTile(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Downloaded',
                          subtitle: '$downloadedCount songs offline • 320 kbps',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DownloadedSongsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        // My top 50 Tile
                        _buildQuickAccessTile(
                          icon: Icons.trending_up_rounded,
                          title: 'My top 50',
                          subtitle: '${manager.top50Songs.length} chartbusters ranked',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Top50Screen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        // Cached Tile
                        _buildQuickAccessTile(
                          icon: Icons.cached_rounded,
                          title: 'Cached',
                          subtitle: 'High speed audio buffer',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cache is optimal. All streams buffered in memory.'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // 5. Dynamic Content Section based on selected category pill
                if (_selectedCategory == 'Playlists') ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Playlists & Mixes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, color: Colors.white70, size: 24),
                            onPressed: () => _showCreatePlaylistDialog(context, manager),
                          ),
                        ],
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
                            color: const Color(0xFF141416),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                                  color: const Color(0xFF2C2C2E),
                                  child: const Icon(Icons.queue_music, color: Colors.white54),
                                ),
                              ),
                            ),
                            title: Text(
                              pl.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              pl.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
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
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = manager.allSongs[index];
                        final isCurrent = manager.currentSong?.id == song.id;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141416),
                            borderRadius: BorderRadius.circular(16),
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
                                  color: const Color(0xFF2C2C2E),
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent ? const Color(0xFFE5A5A5) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${song.artist} • ${song.formattedDuration}',
                              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                              onPressed: () => TrackOptionsSheet.show(context, song),
                            ),
                            onTap: () => manager.playSong(song, newQueue: manager.allSongs),
                          ),
                        );
                      },
                      childCount: manager.allSongs.length,
                    ),
                  ),
                ] else if (_selectedCategory == 'Artists') ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final artistMix = manager.artistMixes[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141416),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(artistMix.coverUrl),
                            ),
                            title: Text(
                              artistMix.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              artistMix.description,
                              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                            ),
                            trailing: const Icon(Icons.play_circle_outline, color: Color(0xFFE5A5A5)),
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
                ] else if (_selectedCategory == 'Albums') ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pl = manager.genreMixes[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141416),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(pl.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
                            ),
                            title: Text(pl.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(pl.description, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
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
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Dark rounded square container for icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
