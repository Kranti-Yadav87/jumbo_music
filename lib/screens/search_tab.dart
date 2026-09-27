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
      'name': 'Lo-Fi Chill & Rain',
      'query': 'Lo-Fi Study Beats',
      'colors': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      'icon': Icons.nightlight_round,
    },
    {
      'name': 'EDM & Party',
      'query': 'EDM Workout',
      'colors': [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'name': 'Acoustic Coffee',
      'query': 'Acoustic Guitar',
      'colors': [Color(0xFF10B981), Color(0xFF059669)],
      'icon': Icons.spa_rounded,
    },
    {
      'name': 'Global Top Hits',
      'query': 'Top Global Hits',
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

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final manager = MusicPlayerManager();
      // First find local matches
      final localMatches = manager.allSongs.where((s) {
        final q = trimmed.toLowerCase();
        return s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q) ||
            s.genre.toLowerCase().contains(q);
      }).toList();

      // Fetch live matches from Aura-Stream (JioSaavn 320kbps master stream)
      final onlineMatches = await MusicApiService.searchLiveSongs(trimmed, limit: 30);

      // Merge results avoiding duplicate audio URLs
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
                // Search Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Search & Explore',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search Input Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search songs, artists (e.g. Arijit Singh)...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF818CF8),
                            ),
                            suffixIcon: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF818CF8)),
                                      ),
                                    ),
                                  )
                                : _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white54),
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

                // Search Results or Browse View
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
              'Searching worldwide music catalog...',
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
              'No results for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check the spelling or try another artist',
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
                  '${_searchResults.length} live tracks found',
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
          // Quick Artist Chips
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Top Artists & Singers',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
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

          const SizedBox(height: 20),

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
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.3),
                        blurRadius: 10,
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
