import 'package:flutter/material.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import '../widgets/library/library_header.dart';
import '../widgets/library/library_category_tabs.dart';
import '../widgets/library/library_sub_bar.dart';
import '../widgets/library/library_dialogs.dart';
import '../widgets/library/library_playlists_view.dart';
import '../widgets/library/library_songs_view.dart';
import '../widgets/library/library_mixes_views.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _selectedCategory = 'Playlists';
  bool _isAscending = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['Playlists', 'Songs', 'Albums', 'Artists'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final downloadService = DownloadService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF081220) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E2D4A) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF2B3E63)
        : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top App Brand Bar
                SliverToBoxAdapter(
                  child: LibraryTopBrandBar(
                    isDark: isDark,
                    onHelpTap: () => showLibraryHelpDialog(context),
                  ),
                ),

                // 2. "Library" Title & Plus Button
                SliverToBoxAdapter(
                  child: LibraryTitleRow(
                    isDark: isDark,
                    onAddTap: () => showCreatePlaylistDialog(context, manager),
                  ),
                ),

                // 3. Category Tabs
                SliverToBoxAdapter(
                  child: LibraryCategoryTabs(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    isDark: isDark,
                    onSelectCategory: (cat) =>
                        setState(() => _selectedCategory = cat),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 4. Sub-bar: items count, AZ toggle, options sheet, search
                SliverToBoxAdapter(
                  child: LibrarySubBar(
                    itemCount: _selectedCategory == 'Playlists'
                        ? 4
                        : manager.allSongs.length,
                    isAscending: _isAscending,
                    isDark: isDark,
                    onToggleSort: () =>
                        setState(() => _isAscending = !_isAscending),
                    onOptionsTap: () => showLibraryOptionsSheet(
                      context,
                      manager,
                      isAscending: _isAscending,
                      onSortChanged: (val) =>
                          setState(() => _isAscending = val),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // 5. Views for selected category
                if (_selectedCategory == 'Playlists')
                  LibraryPlaylistsSliverView(
                    manager: manager,
                    downloadService: downloadService,
                    isDark: isDark,
                    cardColor: cardColor,
                    cardBorder: cardBorder,
                  )
                else if (_selectedCategory == 'Songs')
                  LibrarySongsSliverView(
                    manager: manager,
                    isDark: isDark,
                    cardColor: cardColor,
                    cardBorder: cardBorder,
                  )
                else if (_selectedCategory == 'Albums')
                  LibraryAlbumsSliverView(
                    manager: manager,
                    isDark: isDark,
                    cardColor: cardColor,
                    cardBorder: cardBorder,
                  )
                else if (_selectedCategory == 'Artists')
                  LibraryArtistsSliverView(
                    manager: manager,
                    isDark: isDark,
                    cardColor: cardColor,
                    cardBorder: cardBorder,
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        );
      },
    );
  }
}
