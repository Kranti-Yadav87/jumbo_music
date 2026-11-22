import 'package:flutter/material.dart';

import '../../config/discovery_categories.dart';
import '../../models/song.dart';
import '../../services/category_affinity.dart';
import '../../services/database_service.dart';
import '../../services/music_api_service.dart';
import '../../services/music_player_manager.dart';
import '../video_thumbnail_card.dart';

/// YouTube-style Home feed: category pills on top, 16:9 thumbnail feed below.
/// "All" shows the live trending mix; other pills load that category live.
class YouTubeHomeFeed extends StatefulWidget {
  const YouTubeHomeFeed({super.key});

  @override
  State<YouTubeHomeFeed> createState() => _YouTubeHomeFeedState();
}

class _YouTubeHomeFeedState extends State<YouTubeHomeFeed> {
  static const int _pageSize = 8;
  static const int _maxItems = 24;

  String _category = 'All';
  int _visible = _pageSize;
  final Set<String> _loadingCategories = {};
  bool _failed = false;
  final Map<String, List<Song>> _cache = {};

  List<Song> _dedupe(List<Song> songs) {
    final seenIds = <String>{};
    final seenKeys = <String>{};
    return songs.where((s) {
      final key = SongParserUtils.searchDeduplicationKey(s);
      return seenIds.add(s.id) && (key.isEmpty || seenKeys.add(key));
    }).toList();
  }

  Future<void> _load(String category) async {
    final query = kDiscoveryCategories[category] ?? '';
    if (query.isEmpty || _loadingCategories.contains(category)) return;
    setState(() {
      _loadingCategories.add(category);
      _failed = false;
    });
    try {
      final songs = await MusicApiService.searchLiveSongs(
        query,
        limit: _maxItems,
      );
      if (!mounted) return;
      setState(() {
        _cache[category] = _dedupe(songs);
        _loadingCategories.remove(category);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCategories.remove(category);
        if (_category == category) {
          _failed = true;
        }
      });
    }
  }

  void _select(String category) {
    if (category == _category) return;
    setState(() {
      _category = category;
      _visible = _pageSize;
      _failed = false;
    });
    if (category != 'All' && !_cache.containsKey(category)) _load(category);
  }

  void _play(Song song, List<Song> feed) {
    CategoryAffinity.recordPlay(_category);
    MusicPlayerManager().playSongFromSearch(song, searchResults: feed);
    openNowPlaying(context, song);
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    return AnimatedBuilder(
      animation: Listenable.merge([manager, DatabaseService.instance]),
      builder: (context, _) {
        final feed = _category == 'All'
            ? _dedupe([
                ...manager.onlineTrending,
                ...manager.newReleases,
              ]).take(_maxItems).toList()
            : (_cache[_category] ?? const <Song>[]);
        final isLoading = _category == 'All'
            ? manager.isLoadingTrending && feed.isEmpty
            : _loadingCategories.contains(_category) && feed.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChips(),
            const SizedBox(height: 6),
            if (isLoading)
              const _FeedSkeleton()
            else if (feed.isEmpty)
              _buildEmpty()
            else
              _buildGrid(feed),
          ],
        );
      },
    );
  }

  Widget _buildChips() {
    final categories = CategoryAffinity.orderedForCurrentUser(
      kDiscoveryCategories.keys.toList(),
    );
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == _category;
          return ChoiceChip(
            key: ValueKey('home-feed-category-${category.toLowerCase()}'),
            label: Text(category),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => _select(category),
            selectedColor: Colors.white,
            backgroundColor: const Color(0xFF121212),
            side: BorderSide(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.12),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Song> feed) {
    final shown = feed.take(_visible).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        const hPad = 16.0;
        const spacing = 16.0;
        final width = constraints.maxWidth - hPad * 2;
        final columns = width >= 1200
            ? 4
            : width >= 820
            ? 3
            : width >= 540
            ? 2
            : 1;
        final tileWidth = (width - spacing * (columns - 1)) / columns;
        return Column(
          children: [
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: hPad),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shown.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: 18,
                mainAxisExtent: videoThumbnailCardExtent(tileWidth),
              ),
              itemBuilder: (context, index) => VideoThumbnailCard(
                song: shown[index],
                compact: false,
                onPlay: () => _play(shown[index], feed),
              ),
            ),
            if (feed.length > _visible)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  key: const ValueKey('home-feed-show-more-button'),
                  onPressed: () => setState(() => _visible += _pageSize),
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Show more',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Container(
      key: const ValueKey('home-feed-empty-state'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering_error_rounded, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _failed
                  ? 'Could not load $_category right now.'
                  : 'Nothing to show in $_category yet.',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            key: const ValueKey('home-feed-retry-button'),
            onPressed: () => _category == 'All'
                ? MusicPlayerManager().fetchOnlineTrending()
                : _load(_category),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('home-feed-loading'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(2, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 220,
                  height: 12,
                  color: const Color(0xFF151515),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 140,
                  height: 10,
                  color: const Color(0xFF151515),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
