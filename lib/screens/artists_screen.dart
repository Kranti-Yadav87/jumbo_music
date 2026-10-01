import 'package:flutter/material.dart';
import '../data/music_repository.dart';
import '../models/playlist.dart';
import '../services/music_api_service.dart';
import '../services/music_player_manager.dart';
import '../services/theme_service.dart';
import 'playlist_detail_screen.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, String>> allArtists = [
    ...MusicRepository.popularArtists,
    {
      'id': 'art_kishore',
      'name': 'Kishore Kumar',
      'role': 'Evergreen Legend',
      'listeners': '35M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Kishore_Kumar_500x500.jpg',
      'query': 'Kishore Kumar evergreen hits',
    },
    {
      'id': 'art_lata',
      'name': 'Lata Mangeshkar',
      'role': 'Nightingale of India',
      'listeners': '38M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Lata_Mangeshkar_500x500.jpg',
      'query': 'Lata Mangeshkar golden hits',
    },
    {
      'id': 'art_rafi',
      'name': 'Mohammed Rafi',
      'role': 'Soul of Indian Cinema',
      'listeners': '32M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Mohammed_Rafi_500x500.jpg',
      'query': 'Mohammed Rafi classic hits',
    },
    {
      'id': 'art_kk',
      'name': 'KK (Krishnakumar)',
      'role': 'Voice of a Generation',
      'listeners': '27M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/KK_500x500.jpg',
      'query': 'KK hits',
    },
    {
      'id': 'art_kumarsanu',
      'name': 'Kumar Sanu',
      'role': 'King of 90s Melodies',
      'listeners': '29M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Kumar_Sanu_500x500.jpg',
      'query': 'Kumar Sanu 90s romantic hits',
    },
    {
      'id': 'art_alkayagnik',
      'name': 'Alka Yagnik',
      'role': '90s Melody Queen',
      'listeners': '31M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Alka_Yagnik_500x500.jpg',
      'query': 'Alka Yagnik superhits',
    },
    {
      'id': 'art_sonunigam',
      'name': 'Sonu Nigam',
      'role': 'Lord of Vocals',
      'listeners': '25M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Sonu_Nigam_500x500.jpg',
      'query': 'Sonu Nigam romantic hits',
    },
    {
      'id': 'art_jagjit',
      'name': 'Jagjit Singh',
      'role': 'King of Ghazals',
      'listeners': '20M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Jagjit_Singh_500x500.jpg',
      'query': 'Jagjit Singh ghazals',
    },
  ];

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
      limit: 30,
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
        MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = allArtists.where((a) {
      final name = (a['name'] ?? '').toLowerCase();
      final role = (a['role'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      return name.contains(query) || role.contains(query);
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search singers & artists (Kishore, Arijit, KK...)...',
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

          // Artist Grid
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
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 140),
          ),
        ],
      ),
    );
  }
}
