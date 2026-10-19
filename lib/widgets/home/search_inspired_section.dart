import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';
import '../../services/music_api_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/theme_service.dart';
import 'home_section_header.dart';
import 'song_cover_card.dart';

enum _FeedMode { search, listening, trending }

/// Personalized section that dynamically recommends tracks based on user's recent search queries.
class SearchInspiredSection extends StatefulWidget {
  const SearchInspiredSection({super.key});

  @override
  State<SearchInspiredSection> createState() => _SearchInspiredSectionState();
}

class _SearchInspiredSectionState extends State<SearchInspiredSection> {
  String? _selectedChipQuery;
  String? _activeLoadedQuery;
  String? _lastTopSearchQuery;
  List<Song> _songs = [];
  bool _isLoading = false;
  final Map<String, List<Song>> _queryCache = {};

  static const List<String> _curatedTrendingChips = [
    'Trending Hits',
    'Bollywood 90s',
    'Punjabi Hits',
    'Romantic Melodies',
    'Lofi Beats',
  ];

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.addListener(_onDatabaseChanged);
    _syncQueryAndLoad();
  }

  @override
  void dispose() {
    DatabaseService.instance.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    if (!mounted) return;
    final db = DatabaseService.instance;
    final currentTopSearch = db.searchHistory.isNotEmpty
        ? db.searchHistory.first
        : null;

    if (currentTopSearch != null && currentTopSearch != _lastTopSearchQuery) {
      _lastTopSearchQuery = currentTopSearch;
      _selectedChipQuery = null;
    }

    _syncQueryAndLoad();
  }

  (_FeedMode, String, List<String>) _resolveModeAndQuery(DatabaseService db) {
    if (db.searchHistory.isNotEmpty) {
      final chips = db.searchHistory.take(8).toList();
      final topQuery = db.searchHistory.first;
      final effective = _selectedChipQuery ?? topQuery;
      return (_FeedMode.search, effective, chips);
    }

    if (db.historySongs.isNotEmpty) {
      final artists = <String>[];
      for (final s in db.historySongs) {
        final primary = s.artist.split(',')[0].split('&')[0].trim();
        if (primary.isNotEmpty && !artists.contains(primary)) {
          artists.add(primary);
        }
        if (artists.length >= 6) break;
      }
      if (artists.isNotEmpty) {
        final effective = _selectedChipQuery ?? artists.first;
        return (_FeedMode.listening, effective, artists);
      }
    }

    final effective = _selectedChipQuery ?? _curatedTrendingChips.first;
    return (_FeedMode.trending, effective, _curatedTrendingChips);
  }

  void _syncQueryAndLoad() {
    final db = DatabaseService.instance;
    final (_, effectiveQuery, _) = _resolveModeAndQuery(db);

    if (effectiveQuery != _activeLoadedQuery && !_isLoading) {
      _loadQuery(effectiveQuery);
    }
  }

  Future<void> _loadQuery(String query) async {
    final sanitized = query
        .replaceAll(
          RegExp(
            r'["'
            ']',
          ),
          '',
        )
        .trim();
    if (sanitized.isEmpty) return;

    _activeLoadedQuery = sanitized;

    if (_queryCache.containsKey(sanitized) &&
        _queryCache[sanitized]!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _songs = _queryCache[sanitized]!;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await MusicApiService.searchLiveSongs(
        '$sanitized hits',
        limit: 22,
      );
      if (!mounted) return;

      final validSongs = results.isNotEmpty
          ? results
          : await MusicApiService.searchLiveSongs(sanitized, limit: 22);

      if (!mounted) return;

      final cleanSongs = SongParserUtils.deduplicateSongs(validSongs);
      if (cleanSongs.isNotEmpty) {
        _queryCache[sanitized] = cleanSongs;
      }

      if (mounted) {
        setState(() {
          _songs = cleanSongs;
          _isLoading = false;
        });
      }
    } catch (error) {
      CrashReportingService.swallow(
        error,
        'search_inspired_section.dart:_loadQuery',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;

    return AnimatedBuilder(
      animation: db,
      builder: (context, _) {
        final (mode, effectiveQuery, chips) = _resolveModeAndQuery(db);

        final String title;
        final String subtitle;
        switch (mode) {
          case _FeedMode.search:
            title = 'Inspired by your search';
            subtitle = 'Based on "$effectiveQuery"';
            break;
          case _FeedMode.listening:
            title = 'Inspired by your listening';
            subtitle = 'Because you listened to $effectiveQuery';
            break;
          case _FeedMode.trending:
            title = 'Trending for you';
            subtitle = 'Curated mix based on top trends';
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(title: title, subtitle: subtitle),

            // Interactive query chips
            if (chips.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chips.length,
                  itemBuilder: (context, index) {
                    final term = chips[index];
                    final isSelected =
                        term.toLowerCase() == effectiveQuery.toLowerCase();

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _selectedChipQuery = term;
                          });
                          _loadQuery(term);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF4F46E5),
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : (AppThemeManager.instance.isDarkMode
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF818CF8)
                                  : (AppThemeManager.instance.isDarkMode
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                term,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppThemeManager.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            if (_isLoading)
              const SizedBox(
                height: 215,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF818CF8),
                    ),
                  ),
                ),
              )
            else if (_songs.isNotEmpty)
              SongCoverRow(songs: _songs)
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}
