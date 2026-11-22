import 'dart:async';

import 'package:flutter/material.dart';

import '../config/discovery_categories.dart';
import '../models/song.dart';
import '../services/category_affinity.dart';
import '../services/database_service.dart';
import '../services/music_api_service.dart';
import '../services/music_player_manager.dart';
import '../widgets/video_thumbnail_card.dart';
import '../widgets/voice_search_button.dart';

class SearchDiscoveryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SearchDiscoveryScreen({super.key, this.onBack});

  @override
  State<SearchDiscoveryScreen> createState() => _SearchDiscoveryScreenState();
}

class _SearchDiscoveryScreenState extends State<SearchDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isListening = false;
  String? _errorMessage;
  List<Song> _searchResults = [];
  List<String> _suggestions = [];

  static const _categories = kDiscoveryCategories;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _suggestions = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    final cached = MusicApiService.getCachedSearch(query);
    final local = _localMatches(query);
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _searchQuery = query;
        _searchResults = cached;
        _suggestions = _buildSuggestions(query, cached);
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _searchResults = local;
      _suggestions = _buildSuggestions(query, local);
      _isLoading = true;
      _errorMessage = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 320), () async {
      try {
        final online = await MusicApiService.searchLiveSongs(query, limit: 30);
        final combined = _mergeResults([...online, ...local]);
        if (!mounted || _searchQuery != query) return;
        setState(() {
          _searchResults = combined;
          _suggestions = _buildSuggestions(query, combined);
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted || _searchQuery != query) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Search is taking longer than expected.';
        });
      }
    });
  }

  List<Song> _localMatches(String query) {
    final normalized = query.toLowerCase();
    return MusicPlayerManager().allSongs.where((song) {
      return song.title.toLowerCase().contains(normalized) ||
          song.artist.toLowerCase().contains(normalized) ||
          song.album.toLowerCase().contains(normalized) ||
          song.genre.toLowerCase().contains(normalized);
    }).toList();
  }

  List<Song> _mergeResults(List<Song> source) {
    final seenIds = <String>{};
    final seenNames = <String>{};
    final merged = <Song>[];
    for (final song in source) {
      final nameKey =
          '${song.title.toLowerCase().trim()}|${song.artist.toLowerCase().trim()}';
      if (seenIds.add(song.id) && seenNames.add(nameKey)) {
        merged.add(song);
      }
    }
    return merged;
  }

  List<String> _buildSuggestions(String query, List<Song> results) {
    final suggestions = <String>[query];
    final history = DatabaseService.instance.searchHistory
        .where((term) => term.toLowerCase().contains(query.toLowerCase()))
        .toList();
    for (final term in [
      ...history,
      ...results.map((song) => song.title),
      ...results.map((song) => song.artist),
    ]) {
      if (term.trim().isEmpty ||
          suggestions.any((item) => item.toLowerCase() == term.toLowerCase())) {
        continue;
      }
      suggestions.add(term);
      if (suggestions.length == 6) break;
    }
    return suggestions;
  }

  void _triggerSearch(String term) {
    final query = term.trim();
    if (query.isEmpty) return;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    DatabaseService.instance.addSearchQuery(query);
    _onSearchChanged(query);
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    final query = _categories[category] ?? '';
    if (query.isEmpty) {
      _searchController.clear();
      _onSearchChanged('');
      return;
    }
    _triggerSearch(query);
    _focusNode.unfocus();
  }

  void _playSong(Song song) {
    DatabaseService.instance.addSearchQuery(
      _searchQuery.isNotEmpty ? _searchQuery : song.title,
    );
    CategoryAffinity.recordPlay(_selectedCategory);
    final manager = MusicPlayerManager();
    manager.playSongFromSearch(song, searchResults: _searchResults);
    openNowPlaying(context, song);
  }

  void _goBack() {
    _focusNode.unfocus();
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final manager = MusicPlayerManager();
    return AnimatedBuilder(
      animation: Listenable.merge([db, manager]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF030303),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildCategoryChips(context)),
                if (_searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildDiscovery(context, db.searchHistory),
                  )
                else ...[
                  if (_suggestions.length > 1)
                    SliverToBoxAdapter(child: _buildSuggestionsPanel(context)),
                  SliverToBoxAdapter(child: _buildResultsHeader(context)),
                  if (_isLoading && _searchResults.isEmpty)
                    const SliverToBoxAdapter(child: _SearchLoadingState())
                  else if (_errorMessage != null && _searchResults.isEmpty)
                    SliverToBoxAdapter(child: _buildErrorState(context))
                  else if (_searchResults.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState(context))
                  else
                    SliverToBoxAdapter(child: _buildResultsGrid(context)),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 10),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('search-back-button'),
            tooltip: 'Back',
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: TextField(
                key: const ValueKey('search-input-field'),
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  final query = value.trim();
                  if (query.isNotEmpty) {
                    DatabaseService.instance.addSearchQuery(query);
                  }
                },
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: const Color(0xFFFF0000),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white60,
                  ),
                  suffixIcon: VoiceSearchButton(
                    onListeningChanged: (listening) {
                      if (mounted) setState(() => _isListening = listening);
                    },
                    onWords: (words, isFinal) {
                      if (isFinal) {
                        _triggerSearch(words);
                        _focusNode.unfocus();
                      } else {
                        // Show interim speech without firing repeated
                        // network searches. Search once when speech is final.
                        _debounceTimer?.cancel();
                        _searchController.value = TextEditingValue(
                          text: words,
                          selection: TextSelection.collapsed(
                            offset: words.length,
                          ),
                        );
                      }
                    },
                  ),
                  hintText: _isListening
                      ? 'Listening… say a song or artist'
                      : 'Search songs, artists, albums...',
                  hintStyle: TextStyle(
                    color: _isListening
                        ? const Color(0xFFFF6B6B)
                        : Colors.white38,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              key: const ValueKey('search-clear-button'),
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              icon: const Icon(Icons.close_rounded, color: Colors.white60),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories.keys.elementAt(index);
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            key: ValueKey('category-chip-${category.toLowerCase()}'),
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => _selectCategory(category),
            selectedColor: Colors.white,
            backgroundColor: const Color(0xFF121212),
            side: BorderSide(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.12),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscovery(BuildContext context, List<String> recentSearches) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search smarter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (recentSearches.isNotEmpty)
                TextButton(
                  key: const ValueKey('search-clear-history-button'),
                  onPressed: () =>
                      DatabaseService.instance.clearSearchHistory(),
                  child: const Text(
                    'Clear history',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Discover music with instant suggestions, visual results and a queue that keeps going.',
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
          const SizedBox(height: 22),
          if (recentSearches.isNotEmpty) ...[
            const _SectionLabel(
              icon: Icons.history_rounded,
              label: 'Recent searches',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches.take(8).map((term) {
                return InputChip(
                  key: ValueKey('search-history-chip-${term.toLowerCase()}'),
                  avatar: const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                  label: Text(term),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  backgroundColor: const Color(0xFF121212),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  onPressed: () => _triggerSearch(term),
                  onDeleted: () =>
                      DatabaseService.instance.removeSearchQuery(term),
                  deleteIconColor: Colors.white38,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          const _SectionLabel(
            icon: Icons.explore_rounded,
            label: 'Browse by mood',
          ),
          const SizedBox(height: 12),
          _DiscoveryHero(onTap: () => _selectCategory('Music')),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 5, 18, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: _suggestions.skip(1).take(5).map((suggestion) {
          return ListTile(
            key: ValueKey('search-suggestion-${suggestion.toLowerCase()}'),
            dense: true,
            leading: const Icon(
              Icons.search_rounded,
              color: Colors.white54,
              size: 19,
            ),
            title: Text(
              suggestion,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            trailing: const Icon(
              Icons.north_west_rounded,
              color: Colors.white38,
              size: 16,
            ),
            onTap: () {
              _triggerSearch(suggestion);
              _focusNode.unfocus();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _searchResults.isEmpty
                  ? 'Results for "$_searchQuery"'
                  : 'Top results',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF0000),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1250
            ? 4
            : constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 18,
            mainAxisExtent: columns == 1 ? 98 : 286,
          ),
          itemBuilder: (context, index) {
            return VideoThumbnailCard(
              song: _searchResults[index],
              compact: columns == 1,
              onPlay: () => _playSong(_searchResults[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(44),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.white24, size: 54),
          const SizedBox(height: 14),
          Text(
            'No results for "$_searchQuery"',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Try an artist, song title or a mood like “chill” or “party”.',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF251010),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_tethering_error_rounded,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => _onSearchChanged(_searchQuery),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF0000), size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _DiscoveryHero extends StatelessWidget {
  final VoidCallback onTap;

  const _DiscoveryHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF3A0909), Color(0xFF151515)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.red.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF0000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Play something new',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Jump into today’s music and let Smart Radio build your next queue.',
                      style: TextStyle(
                        color: Colors.white60,
                        height: 1.3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            height: 76,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }),
      ),
    );
  }
}
