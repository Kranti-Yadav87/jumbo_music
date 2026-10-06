import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/database_service.dart';
import '../services/music_player_manager.dart';
import '../services/presence_service.dart';
import '../widgets/mini_player.dart';
import 'friends/add_friend_dialog.dart';
import 'friends/friend_listening_tile.dart';
import 'friends/live_jam_dialog.dart';
import 'friends/shared_playlist_dialog.dart';
import 'playlist_detail_screen.dart';
import '../widgets/cover_image.dart';

class FriendsScreen extends StatefulWidget {
  final bool showHeader;

  const FriendsScreen({super.key, this.showHeader = true});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';
  bool _isLiveJamActive = false;
  final String _activeJamRoom = 'JUMBO-SYNC-8821';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final manager = MusicPlayerManager();
    final presence = PresenceService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([db, manager, presence]),
      builder: (context, _) {
        final allFriends = presence.liveFriends;
        final filteredFriends = _searchFilter.isEmpty
            ? allFriends
            : allFriends
                  .where(
                    (f) =>
                        f.name.toLowerCase().contains(_searchFilter) ||
                        f.email.toLowerCase().contains(_searchFilter) ||
                        f.currentSongTitle.toLowerCase().contains(
                          _searchFilter,
                        ),
                  )
                  .toList();

        final sharedPlaylists = db.sharedPlaylists;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0D0D15)
              : const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (widget.showHeader) _buildTopHeader(context, isDark),
                _buildSearchBar(isDark),
                if (_isLiveJamActive) _buildLiveJamBanner(context, isDark),
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Live Friends & Activity
                      _buildFriendsTab(filteredFriends, manager, isDark),
                      // Tab 2: Shared Duo Blend Playlists
                      _buildPlaylistsTab(
                        context,
                        sharedPlaylists,
                        manager,
                        isDark,
                      ),
                    ],
                  ),
                ),
                if (manager.currentSong != null) const MiniPlayer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Text(
            'Friends & Jam',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Live Jam Room',
            icon: Icon(
              Icons.podcasts_rounded,
              color: _isLiveJamActive
                  ? const Color(0xFFFF5E3A)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            onPressed: () => LiveJamDialog.show(
              context,
              roomCode: _activeJamRoom,
              isLiveJamActive: _isLiveJamActive,
              onJamToggled: (active) =>
                  setState(() => _isLiveJamActive = active),
            ),
          ),
          IconButton(
            tooltip: 'Add Friend',
            icon: const Icon(
              Icons.person_add_rounded,
              color: Color(0xFFFF5E3A),
            ),
            onPressed: () => AddFriendDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search friends, emails, or listening songs...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFFF5E3A),
            size: 20,
          ),
          suffixIcon: _searchFilter.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchFilter = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (v) =>
            setState(() => _searchFilter = v.trim().toLowerCase()),
      ),
    );
  }

  Widget _buildLiveJamBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5E3A), Color(0xFFFF2A54)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Jam Session Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Room: $_activeJamRoom • Synced playback',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: () => setState(() => _isLiveJamActive = false),
            child: const Text('Leave', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFFFF5E3A),
      unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
      indicatorColor: const Color(0xFFFF5E3A),
      indicatorWeight: 3,
      tabs: const [
        Tab(
          icon: Icon(Icons.people_alt_rounded, size: 20),
          text: 'Friends Activity',
        ),
        Tab(
          icon: Icon(Icons.queue_music_rounded, size: 20),
          text: 'Duo Playlists',
        ),
      ],
    );
  }

  Widget _buildFriendsTab(
    List dynamicFriends,
    MusicPlayerManager manager,
    bool isDark,
  ) {
    if (dynamicFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E3A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  size: 48,
                  color: Color(0xFFFF5E3A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Friends Connected Yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your friend\'s email to see what they are listening to in real-time and jam together!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Friend Now'),
                onPressed: () => AddFriendDialog.show(context),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: dynamicFriends.length,
      itemBuilder: (context, index) {
        final friend = dynamicFriends[index];
        return FriendListeningTile(
          friend: friend,
          manager: manager,
          onJamStarted: () => setState(() => _isLiveJamActive = true),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(
    BuildContext context,
    List<Playlist> playlists,
    MusicPlayerManager manager,
    bool isDark,
  ) {
    if (playlists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.playlist_add_rounded,
                  size: 48,
                  color: Color(0xFFA855F7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Duo Blend Playlists',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create a shared blend playlist with a friend to combine your music tastes in real-time!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final p = playlists[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: CoverImage(
              imageUrl: p.coverUrl,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(10),
              fallbackBgColor: const Color(0xFFA855F7).withValues(alpha: 0.2),
              fallbackIcon: Icons.queue_music_rounded,
            ),
            title: Text(
              p.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              '${p.songs.length} tracks • Collaborative Blend',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFFFF5E3A),
              ),
              onPressed: () =>
                  SharedPlaylistDialog.showAddSongBottomSheet(context, p),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlist: p),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
