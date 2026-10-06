import 'package:flutter/material.dart';
import '../models/friend_request.dart';
import '../models/playlist.dart';
import '../services/database_service.dart';
import '../services/friend_request_service.dart';
import '../services/music_player_manager.dart';
import '../services/presence_service.dart';
import '../widgets/mini_player.dart';
import 'friends/add_friend_dialog.dart';
import 'friends/friend_listening_tile.dart';
import 'friends/incoming_requests_section.dart';
import 'friends/live_jam_dialog.dart';
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
  String? _activeJamRoom;

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
    final requestService = FriendRequestService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([db, manager, presence, requestService]),
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
        final incomingRequests = requestService.incomingRequests;

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
                if (_isLiveJamActive && _activeJamRoom != null)
                  _buildLiveJamBanner(context, isDark),
                _buildTabBar(isDark, incomingRequests.length),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Live Friends & Activity + Incoming Requests
                      _buildFriendsTab(
                        filteredFriends,
                        incomingRequests,
                        manager,
                        isDark,
                      ),
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
            'Friends & Social',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E3A).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: Color(0xFFFF5E3A),
                size: 20,
              ),
            ),
            tooltip: 'Send Friend Request',
            onPressed: () => AddFriendDialog.show(context),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sensors_rounded,
                color: Color(0xFF0EA5E9),
                size: 20,
              ),
            ),
            onPressed: () => LiveJamDialog.show(
              context,
              roomCode: _activeJamRoom,
              isLiveJamActive: _isLiveJamActive,
              onJamToggled: (active, roomCode) {
                setState(() {
                  _isLiveJamActive = active;
                  _activeJamRoom = roomCode;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171720) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) =>
              setState(() => _searchFilter = val.trim().toLowerCase()),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search friends by name, email or track...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 20,
            ),
            suffixIcon: _searchFilter.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchFilter = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveJamBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Connected to Live Jam Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  'Room: ${_activeJamRoom ?? ''} • Synced playback',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: () => setState(() {
              _isLiveJamActive = false;
              _activeJamRoom = null;
            }),
            child: const Text('Leave', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, int pendingRequestsCount) {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFFFF5E3A),
      unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
      indicatorColor: const Color(0xFFFF5E3A),
      indicatorWeight: 3,
      tabs: [
        Tab(
          icon: pendingRequestsCount > 0
              ? Badge(
                  label: Text('$pendingRequestsCount'),
                  backgroundColor: const Color(0xFFFF5E3A),
                  child: const Icon(Icons.people_alt_rounded, size: 20),
                )
              : const Icon(Icons.people_alt_rounded, size: 20),
          text: 'Friends Activity',
        ),
        const Tab(
          icon: Icon(Icons.queue_music_rounded, size: 20),
          text: 'Duo Playlists',
        ),
      ],
    );
  }

  Widget _buildFriendsTab(
    List dynamicFriends,
    List<FriendRequest> incomingRequests,
    MusicPlayerManager manager,
    bool isDark,
  ) {
    return CustomScrollView(
      slivers: [
        if (incomingRequests.isNotEmpty)
          SliverToBoxAdapter(
            child: IncomingRequestsSection(
              requests: incomingRequests,
              isDark: isDark,
            ),
          ),
        if (dynamicFriends.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E3A).withOpacity(0.1),
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
                      'Send a friend request with your friend\'s email to see what they are listening to in real-time and jam together!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
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
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final friend = dynamicFriends[index];
                return FriendListeningTile(
                  friend: friend,
                  manager: manager,
                  onJamStarted: () => setState(() => _isLiveJamActive = true),
                );
              }, childCount: dynamicFriends.length),
            ),
          ),
      ],
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
                  color: const Color(0xFFA855F7).withOpacity(0.1),
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
                'No Duo Blend Playlists Yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap on any friend to blend music tastes and create your first synchronized Duo Jam playlist!',
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final p = playlists[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
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
              fallbackBgColor: const Color(0xFFA855F7).withOpacity(0.2),
              fallbackIcon: Icons.queue_music_rounded,
            ),
            title: Text(
              p.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              '${p.songs.length} tracks • ${p.description}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
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
