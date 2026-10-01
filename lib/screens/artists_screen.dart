import 'package:flutter/material.dart';
import '../data/music_repository.dart';
import '../models/playlist.dart';
import '../services/music_api_service.dart';
import 'playlist_detail_screen.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchingLive = false;

  static List<Map<String, String>> get allArtists => MusicRepository.popularArtists;

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('dharshan', 'darshan')
        .replaceAll('rawal', 'raval')
        .replaceAll('shreya', 'shreya')
        .replaceAll('shing', 'singh')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _openArtist(BuildContext context, Map<String, String> artist) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading ${artist['name']} essentials... 🎵'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final songs = await MusicApiService.searchLiveSongs(
      artist['query'] ?? '${artist['name']} hits',
      limit: 35,
    );

    if (songs.isNotEmpty && context.mounted) {
      final playlist = Playlist(
        id: artist['id'] ?? 'art_${artist['name']}',
        title: '${artist['name']} Essentials',
        description: '${artist['role']} • ${artist['listeners'] ?? 'Top Tracks'}',
        coverUrl: (artist['imageUrl']?.isNotEmpty == true)
            ? artist['imageUrl']!
            : songs.first.coverUrl,
        songIds: songs.map((s) => s.id).toList(),
        songs: songs,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load songs for ${artist['name']}. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _searchAndOpenCustomArtist(BuildContext context, String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() => _isSearchingLive = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching "$cleanQuery" on Music Cloud... 🔍'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final songs = await MusicApiService.searchLiveSongs('$cleanQuery hits', limit: 35);
      if (songs.isNotEmpty && context.mounted) {
        final playlist = Playlist(
          id: 'custom_art_${cleanQuery.toLowerCase().replaceAll(' ', '_')}',
          title: '$cleanQuery Essentials',
          description: 'Top tracks & discography for $cleanQuery',
          coverUrl: songs.first.coverUrl,
          songIds: songs.map((s) => s.id).toList(),
          songs: songs,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No tracks found for "$cleanQuery". Try another spelling.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search failed. Please check connection and try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingLive = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawQuery = _searchQuery.toLowerCase().trim();
    final normalizedQuery = _normalize(rawQuery);

    final filtered = allArtists.where((a) {
      if (rawQuery.isEmpty) return true;
      final name = (a['name'] ?? '').toLowerCase();
      final role = (a['role'] ?? '').toLowerCase();
      final keywords = (a['keywords'] ?? '').toLowerCase();
      final query = (a['query'] ?? '').toLowerCase();

      final normalizedName = _normalize(name);
      final normalizedKeywords = _normalize(keywords);

      return name.contains(rawQuery) ||
          role.contains(rawQuery) ||
          keywords.contains(rawQuery) ||
          query.contains(rawQuery) ||
          normalizedName.contains(normalizedQuery) ||
          normalizedKeywords.contains(normalizedQuery);
    }).toList();

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
              'Popular Artists & Singers',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF16161F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  onSubmitted: (val) => _searchAndOpenCustomArtist(context, val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search singers (Darshan Raval, Arijit, Kishore, KK...)...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF818CF8), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // Live Search Action Banner if searching
          if (_searchQuery.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isSearchingLive
                      ? null
                      : () => _searchAndOpenCustomArtist(context, _searchQuery.trim()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: _isSearchingLive
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_sync_rounded, color: Color(0xFF818CF8), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search "$_searchQuery" on Music Cloud',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to fetch all songs and discography live',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Artist Grid
          if (filtered.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final artist = filtered[index];

                    return GestureDetector(
                      onTap: () => _openArtist(context, artist),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF4B2B), Color(0xFFFF416C)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF4B2B).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: ClipOval(
                                child: Image.network(
                                  artist['imageUrl']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1E1E2D),
                                    child: Center(
                                      child: Text(
                                        artist['name']![0],
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              artist['name']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              artist['role']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '▶ Listen Radio',
                                style: TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, color: Colors.white30, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No pre-saved artist found for "$_searchQuery"',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: Text('Search "$_searchQuery" Online'),
                        onPressed: () => _searchAndOpenCustomArtist(context, _searchQuery),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 140),
          ),
        ],
      ),
    );
  }
}
