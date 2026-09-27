import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/music_api_service.dart';
import '../widgets/song_tile.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isLoading = false;
  List<Song> _searchResults = [];

  final List<String> _quickArtists = [
    'Arijit Singh',
    'Diljit Dosanjh',
    'Sidhu Moosewala',
    'Shreya Ghoshal',
    'Atif Aslam',
    'Karan Aujla',
    'AP Dhillon',
    'Anuv Jain',
    'Badshah',
    'Taylor Swift',
    'The Weeknd',
  ];

  final List<Map<String, dynamic>> _genreCards = [
    {
      'name': 'Bollywood Sukoon',
      'query': 'Bollywood Romantic',
      'colors': [Color(0xFFF43F5E), Color(0xFFFB7185)],
      'icon': Icons.music_note_rounded,
    },
    {
      'name': 'Punjabi Bangers',
      'query': 'Punjabi Hits',
      'colors': [Color(0xFFF59E0B), Color(0xFFF97316)],
      'icon': Icons.local_fire_department_rounded,
    },
    {
      'name': 'Lo-Fi Chill & Study',
      'query': 'Lo-Fi Hindi Beats',
      'colors': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      'icon': Icons.nightlight_round,
    },
    {
      'name': 'Desi EDM & Club',
      'query': 'EDM Workout Hits',
      'colors': [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'name': 'Acoustic Coffeehouse',
      'query': 'Acoustic Guitar Hindi',
      'colors': [Color(0xFF10B981), Color(0xFF059669)],
      'icon': Icons.spa_rounded,
    },
    {
      'name': 'Top Global Hits',
      'query': 'Top Global Hits 2026',
      'colors': [Color(0xFFEC4899), Color(0xFFA855F7)],
      'icon': Icons.star_rounded,
    },
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _isLoading = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchQuery = trimmed;
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final manager = MusicPlayerManager();
      // 1. Local matches
      final localMatches = manager.allSongs.where((s) {
        final q = trimmed.toLowerCase();
        return s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q) ||
            s.genre.toLowerCase().contains(q);
      }).toList();

      // 2. Fetch live online matches (JioSaavn 320kbps master)
      final onlineMatches = await MusicApiService.searchLiveSongs(trimmed, limit: 30);

      // Merge avoiding duplicate audio URLs
      final Set<String> seenUrls = {};
      final List<Song> combined = [];

      for (final song in [...localMatches, ...onlineMatches]) {
        if (!seenUrls.contains(song.audioUrl)) {
          seenUrls.add(song.audioUrl);
          combined.add(song);
        }
      }

      if (mounted && _searchQuery == trimmed) {
        setState(() {
          _searchResults = combined;
          _isLoading = false;
        });
      }
    });
  }

  void _triggerSearch(String term) {
    _searchController.text = term;
    _onSearchChanged(term);
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DISCOVER & SEARCH',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF818CF8),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Live Audio Search',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  size: 13,
                                  color: manager.autoplay ? const Color(0xFF10B981) : Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  manager.autoplay ? 'Autoplay: Active' : 'Autoplay: Off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: manager.autoplay ? const Color(0xFF10B981) : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Search Input Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _searchQuery.isNotEmpty
                                ? const Color(0xFF6366F1).withOpacity(0.5)
                                : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search songs, singers (e.g. Kesariya, Diljit)...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF818CF8),
                              size: 24,
                            ),
                            suffixIcon: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF818CF8),
                                        ),
                                      ),
                                    ),
                                  )
                                : _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                        },
                                      )
                                    : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results or Browse
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? _buildSearchResults()
                      : _buildDefaultBrowse(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
            ),
            SizedBox(height: 16),
            Text(
              'Searching 320 kbps live catalog...',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No live tracks found for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try another song, artist, or genre name',
              style: TextStyle(fontSize: 13, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Text(
                  '${_searchResults.length} live tracks • 320 kbps studio',
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ],
              ],
            ),
          );
        }
        final song = _searchResults[index - 1];
        return SongTile(
          song: song,
          index: index,
          playlistContext: _searchResults,
        );
      },
    );
  }

  Widget _buildDefaultBrowse() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smart Autoplay banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.25),
                  const Color(0xFF8B5CF6).withOpacity(0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continuous Radio Autoplay',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Play any searched song and fresh, diverse tracks will automatically queue next without stopping.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Artist Chips
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Text(
              'Trending Artists & Singers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickArtists.map((artist) {
                return ActionChip(
                  avatar: const CircleAvatar(
                    backgroundColor: Color(0xFF6366F1),
                    radius: 10,
                    child: Icon(Icons.person, size: 12, color: Colors.white),
                  ),
                  label: Text(artist),
                  backgroundColor: Colors.white.withOpacity(0.06),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  onPressed: () => _triggerSearch(artist),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // Browse Genres Grid
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Explore by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: _genreCards.length,
            itemBuilder: (context, index) {
              final item = _genreCards[index];
              final String name = item['name'];
              final String query = item['query'];
              final List<Color> colors = item['colors'];
              final IconData icon = item['icon'];

              return GestureDetector(
                onTap: () => _triggerSearch(query),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          icon,
                          size: 54,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
