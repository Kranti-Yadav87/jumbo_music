import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';
import '../../services/music_api_service.dart';
import '../../services/theme_service.dart';
import 'home_section_header.dart';
import 'song_cover_card.dart';

/// Personalized section that dynamically recommends tracks based on user's recent search queries.
class SearchInspiredSection extends StatefulWidget {
  const SearchInspiredSection({super.key});

  @override
  State<SearchInspiredSection> createState() => _SearchInspiredSectionState();
}

class _SearchInspiredSectionState extends State<SearchInspiredSection> {
  String? _activeQuery;
  List<Song> _songs = [];
  bool _isLoading = false;
  final Map<String, List<Song>> _queryCache = {};

  @override
  void initState() {
    super.initState();
    _initSearchFeed();
  }

  void _initSearchFeed() {
    final history = DatabaseService.instance.searchHistory;
    final query = history.isNotEmpty
        ? history.first
        : 'Bollywood & Global Hits';
    _loadQuery(query);
  }

  Future<void> _loadQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _activeQuery = trimmed;
    });

    if (_queryCache.containsKey(trimmed) && _queryCache[trimmed]!.isNotEmpty) {
      setState(() {
        _songs = _queryCache[trimmed]!;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await MusicApiService.searchLiveSongs(
        '$trimmed hits',
        limit: 22,
      );
      if (!mounted) return;

      final validSongs = results.isNotEmpty
          ? results
          : await MusicApiService.searchLiveSongs(trimmed, limit: 22);

      if (!mounted) return;

      if (validSongs.isNotEmpty) {
        _queryCache[trimmed] = validSongs;
      }

      setState(() {
        _songs = validSongs;
        _isLoading = false;
      });
    } catch (_) {
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
        final history = db.searchHistory;
        final effectiveQuery =
            _activeQuery ??
            (history.isNotEmpty ? history.first : 'Bollywood & Global Hits');

        final displayHistory = history.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: history.isNotEmpty
                  ? 'Inspired by your search'
                  : 'Trending for you',
              subtitle: history.isNotEmpty
                  ? 'Based on "$effectiveQuery"'
                  : 'Curated mix based on top trends',
            ),

            // Interactive query chips when user has search history
            if (displayHistory.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayHistory.length,
                  itemBuilder: (context, index) {
                    final term = displayHistory[index];
                    final isSelected =
                        term.toLowerCase() == effectiveQuery.toLowerCase();

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _loadQuery(term),
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
