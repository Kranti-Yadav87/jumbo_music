import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/music_api_service.dart';
import '../widgets/track_options_sheet.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isLoading = false;
  List<Song> _searchResults = [];
  List<String> _suggestions = [];

  final List<String> _popularKeywords = [
    'jiya dhadak dhadak',
    'jiya jale',
    'jiya lage na',
    'jiya re',
    'jiya jiya re',
    'kesariya',
    'apna bana le',
    'diljit dosanjh hits',
    'sidhu moosewala',
    'arijit singh melodies',
    'shreya ghoshal classics',
    'lofi sukoon hindi',
  ];

  @override
  void initState() {
    super.initState();
    _suggestions = _popularKeywords.take(6).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
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
        _suggestions = _popularKeywords.take(6).toList();
      });
      return;
    }

    // Generate dynamic autocomplete suggestions matching query (Screenshot 4)
    final q = trimmed.toLowerCase();
    final matchedSuggestions = <String>[];
    
    // Exact or prefix matches from popular keywords
    for (final kw in _popularKeywords) {
      if (kw.toLowerCase().contains(q) && !matchedSuggestions.contains(kw)) {
        matchedSuggestions.add(kw);
      }
    }
    
    // Add variations if fewer than 5
    if (!matchedSuggestions.contains(trimmed.toLowerCase())) {
      matchedSuggestions.insert(0, trimmed.toLowerCase());
    }
    if (matchedSuggestions.length < 6) {
      matchedSuggestions.add('$trimmed acoustic');
      matchedSuggestions.add('$trimmed lofi remix');
      matchedSuggestions.add('$trimmed 320kbps');
    }

    setState(() {
      _searchQuery = trimmed;
      _isLoading = true;
      _suggestions = matchedSuggestions.take(6).toList();
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final manager = MusicPlayerManager();
      
      // 1. Local matches
      final localMatches = manager.allSongs.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q) ||
            s.genre.toLowerCase().contains(q);
      }).toList();

      // 2. Fetch live online 320 kbps matches from JioSaavn API
      final onlineMatches = await MusicApiService.searchLiveSongs(trimmed, limit: 25);

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
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _onSearchChanged(term);
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Search Bar (Screenshot 4)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),

                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          autofocus: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                          cursorColor: Colors.white,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Search songs, artists...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          ),
                        ),
                      ),

                      // Clear Button (✕)
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),

                      // Globe Button
                      IconButton(
                        icon: const Icon(Icons.language_rounded, color: Colors.white, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Searching global 320 kbps library & multi-language catalogs'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFF1C1C1E)),

                // 2. Body: Autocomplete Suggestions + Top Results (Screenshot 4)
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Autocomplete Suggestions List with ↖ action button
                      if (_suggestions.isNotEmpty)
                        ..._suggestions.map((suggestion) {
                          return InkWell(
                            onTap: () {
                              _triggerSearch(suggestion);
                              _focusNode.unfocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  // Dark rounded search icon container
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141416),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  // North-West arrow action button (Screenshot 4)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.north_west_rounded,
                                      color: Colors.white54,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      // Fills text without submitting
                                      _searchController.text = suggestion;
                                      _searchController.selection = TextSelection.fromPosition(
                                        TextPosition(offset: suggestion.length),
                                      );
                                      _onSearchChanged(suggestion);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      // 3. | Top Results Section (Screenshot 4)
                      if (_searchResults.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Row(
                            children: const [
                              Text(
                                '|  ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Top Results',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._searchResults.map((song) {
                          final isCurrent = manager.currentSong?.id == song.id;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  song.coverUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
                                    color: const Color(0xFF1C1C1E),
                                    child: const Icon(Icons.music_note, color: Colors.white30),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? const Color(0xFFE5A5A5) : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 13,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                                onPressed: () => TrackOptionsSheet.show(context, song),
                              ),
                              onTap: () {
                                manager.playSong(song, newQueue: _searchResults);
                              },
                            ),
                          );
                        }),
                      ],

                      if (_isLoading && _searchResults.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A5A5)),
                            ),
                          ),
                        ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
