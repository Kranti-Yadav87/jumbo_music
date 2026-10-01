import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/music_api_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../widgets/track_options_sheet.dart';
import '../widgets/now_playing_screen.dart';

class SearchTab extends StatefulWidget {
  final VoidCallback? onBack;
  const SearchTab({super.key, this.onBack});

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

  // Trending discovery pills shown ONLY when search history is empty
  final List<String> _trendingTags = [
    'Trending Top 50',
    'Arijit Singh',
    'Bollywood Hits',
    'Punjabi Pop',
    'Diljit Dosanjh',
    'Lo-Fi Sukoon',
    'Romantic Melodies',
    '90s Retro Classics',
    'Shreya Ghoshal',
    'Party & Dance',
  ];

  @override
  void initState() {
    super.initState();
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
        _suggestions = [];
      });
      return;
    }

    final q = trimmed.toLowerCase();

    setState(() {
      _searchQuery = trimmed;
      _isLoading = true;
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

      // Generate dynamic autocomplete suggestions from real search results
      final dynamicSuggestions = <String>[];
      dynamicSuggestions.add(trimmed);

      for (final s in combined) {
        if (!dynamicSuggestions.any((item) => item.toLowerCase() == s.title.toLowerCase()) &&
            dynamicSuggestions.length < 5) {
          dynamicSuggestions.add(s.title);
        }
        if (!dynamicSuggestions.any((item) => item.toLowerCase() == s.artist.toLowerCase()) &&
            dynamicSuggestions.length < 5) {
          dynamicSuggestions.add(s.artist);
        }
      }

      if (mounted && _searchQuery == trimmed) {
        setState(() {
          _searchResults = combined;
          _suggestions = dynamicSuggestions;
          _isLoading = false;
        });
      }
    });
  }

  void _triggerSearch(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    _searchController.text = trimmed;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: trimmed.length),
    );
    DatabaseService.instance.addSearchQuery(trimmed);
    _onSearchChanged(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final db = DatabaseService.instance;
    final isDark = AppThemeManager.instance.isDarkMode;

    return AnimatedBuilder(
      animation: Listenable.merge([manager, db]),
      builder: (context, _) {
        final recentSearches = db.searchHistory;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Search Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: AppThemeManager.textPrimary(context),
                          size: 24,
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),

                      // Text Field
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF14141E) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: TextStyle(
                              color: AppThemeManager.textPrimary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: const Color(0xFF6366F1),
                            onChanged: _onSearchChanged,
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                DatabaseService.instance.addSearchQuery(val.trim());
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Search songs, artists, albums...',
                              hintStyle: TextStyle(
                                color: AppThemeManager.textMuted(context),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),

                      // Clear Button (✕)
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppThemeManager.textSecondary(context),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                ),

                // 2. Body: Recent Searches / Discovery / Search Results
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // A. When Query is Empty -> Show User's Real Search History (with Clear option)
                      if (_searchQuery.isEmpty) ...[
                        if (recentSearches.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.history_rounded,
                                      size: 18,
                                      color: Color(0xFF6366F1),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Recent Searches',
                                      style: TextStyle(
                                        color: AppThemeManager.textPrimary(context),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => db.clearSearchHistory(),
                                  child: const Text(
                                    'Clear all',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...recentSearches.map((term) {
                            return InkWell(
                              onTap: () {
                                _triggerSearch(term);
                                _focusNode.unfocus();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF181822)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.history_rounded,
                                          color: AppThemeManager.textSecondary(context),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        term,
                                        style: TextStyle(
                                          color: AppThemeManager.textPrimary(context),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: AppThemeManager.textMuted(context),
                                        size: 18,
                                      ),
                                      splashRadius: 18,
                                      onPressed: () => db.removeSearchQuery(term),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],

                        // Discover Trending Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 18,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Trending & Discover',
                                style: TextStyle(
                                  color: AppThemeManager.textPrimary(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _trendingTags.map((tag) {
                              return ActionChip(
                                label: Text(tag),
                                labelStyle: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF14141E)
                                    : const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                onPressed: () {
                                  _triggerSearch(tag);
                                  _focusNode.unfocus();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // B. When Query is Typed -> Dynamic Suggestions
                      if (_searchQuery.isNotEmpty && _suggestions.isNotEmpty) ...[
                        ..._suggestions.map((suggestion) {
                          return InkWell(
                            onTap: () {
                              _triggerSearch(suggestion);
                              _focusNode.unfocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF181822)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: AppThemeManager.textSecondary(context),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: TextStyle(
                                        color: AppThemeManager.textPrimary(context),
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.north_west_rounded,
                                      color: AppThemeManager.textMuted(context),
                                      size: 18,
                                    ),
                                    onPressed: () {
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
                      ],

                      // C. Search Results Section
                      if (_searchResults.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Top Results (${_searchResults.length})',
                                style: TextStyle(
                                  color: AppThemeManager.textPrimary(context),
                                  fontSize: 15,
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE2E8F0),
                                    child: Icon(Icons.music_note, color: AppThemeManager.textMuted(context)),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent
                                      ? const Color(0xFF818CF8)
                                      : AppThemeManager.textPrimary(context),
                                  fontSize: 14.5,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppThemeManager.textSecondary(context),
                                  fontSize: 12.5,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: AppThemeManager.textMuted(context),
                                ),
                                onPressed: () => TrackOptionsSheet.show(context, song),
                              ),
                              onTap: () {
                                DatabaseService.instance.addSearchQuery(_searchQuery.isNotEmpty ? _searchQuery : song.title);
                                manager.playSongFromSearch(song);

                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, anim1, anim2) => const NowPlayingScreen(),
                                    transitionsBuilder: (context, anim1, anim2, child) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeOutCubic;
                                      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return SlideTransition(position: anim1.drive(tween), child: child);
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                );
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
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                            ),
                          ),
                        ),

                      if (!_isLoading && _searchQuery.isNotEmpty && _searchResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 54,
                                color: AppThemeManager.textMuted(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No results found for "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppThemeManager.textSecondary(context),
                                ),
                              ),
                            ],
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
