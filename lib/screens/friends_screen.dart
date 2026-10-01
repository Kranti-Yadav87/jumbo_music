import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/music_player_manager.dart';
import '../models/friend.dart';
import '../models/song.dart';
import '../widgets/app_top_header.dart';
import '../screens/playlist_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  final bool showHeader;

  const FriendsScreen({super.key, this.showHeader = true});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _addFriend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address (e.g. friend@email.com)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);
    final friend = await DatabaseService.instance.addFriend(email);
    _emailController.clear();
    setState(() => _isAdding = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${friend.name} to your friends! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFriendListeningOptions(BuildContext context, Friend friend, MusicPlayerManager manager) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF14141E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A1F1B),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF5E3A).withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Text(
                          friend.initials,
                          style: const TextStyle(
                            color: Color(0xFFFF5E3A),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Listening to: ${friend.currentSongTitle} • ${friend.currentSongArtist}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF5E3A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Listen Together (Sync Playback)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E3A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.headphones_rounded, color: Color(0xFFFF5E3A), size: 20),
                  ),
                  title: Text(
                    'Listen Together Now',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Sync & play "${friend.currentSongTitle}" in real-time',
                    style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    // Find or create song matching friend listening
                    final matchingSong = manager.allSongs.firstWhere(
                      (s) => s.title.toLowerCase().contains(friend.currentSongTitle.toLowerCase()) ||
                             s.artist.toLowerCase().contains(friend.currentSongArtist.toLowerCase()),
                      orElse: () => Song(
                        id: friend.currentSongId.isNotEmpty ? friend.currentSongId : 'friend_stream',
                        title: friend.currentSongTitle.isNotEmpty ? friend.currentSongTitle : 'You',
                        artist: friend.currentSongArtist.isNotEmpty ? friend.currentSongArtist : 'Armaan Malik',
                        audioUrl: manager.allSongs.isNotEmpty ? manager.allSongs.first.audioUrl : '',
                        coverUrl: friend.currentSongCover.isNotEmpty ? friend.currentSongCover : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600',
                        duration: const Duration(seconds: 210),
                      ),
                    );
                    manager.playSong(matchingSong);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎧 Now listening with ${friend.name} to "${friend.currentSongTitle}"!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // 2. Create Shared Playlist / Blend with Friend
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.queue_music_rounded, color: Color(0xFFA855F7), size: 20),
                  ),
                  title: Text(
                    'Create Shared Playlist with ${friend.name}',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Collaborative blend playlist where both can add songs',
                    style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreateSharedPlaylistDialog(context, friend, manager);
                  },
                ),

                // 3. Share Current Song
                if (manager.currentSong != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.send_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    title: Text(
                      'Send "${manager.currentSong!.title}" to ${friend.name}',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Share what you are currently listening to',
                      style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sent "${manager.currentSong!.title}" to ${friend.name} 🎵'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateSharedPlaylistDialog(BuildContext context, Friend friend, MusicPlayerManager manager) {
    final titleController = TextEditingController(
      text: '${DatabaseService.instance.userName} + ${friend.name} Blend',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.group_add_rounded, color: Color(0xFFFF5E3A)),
            const SizedBox(width: 10),
            Text(
              'Shared Playlist',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a collaborative playlist with ${friend.name} (${friend.email}). You both can add and listen to the same songs together!',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Playlist Name',
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5E3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                // Collect starter songs from user's favorites or popular tracks
                final starter = manager.favoriteSongs.take(3).toList();
                final playlist = await DatabaseService.instance.createSharedBlendPlaylist(
                  title: title,
                  friend: friend,
                  starterSongs: starter,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlist: playlist),
                    ),
                  );
                }
              }
            },
            child: const Text('Create Blend', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final manager = MusicPlayerManager();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([db, manager]),
      builder: (context, _) {
        final friends = db.friends;
        final friendsListening = db.friendsListening;
        final sharedPlaylists = db.sharedPlaylists;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF101016) : const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top App Header
                if (widget.showHeader)
                  const SliverToBoxAdapter(
                    child: AppTopHeader(title: 'KanaKö'),
                  ),

                // Screen Title "Friends" (Screenshot 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      'Friends',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),

                // "Add Friend by Email" Section (Screenshot 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Friend by Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Email text field with dark rounded style
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF181822) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'friend@email.com',
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      fontSize: 14,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => _addFriend(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Orange/Coral Add Button with User+ icon (Screenshot 2)
                            GestureDetector(
                              onTap: _isAdding ? null : _addFriend,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5E3A),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5E3A).withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isAdding
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_add_alt_1_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // "FRIENDS LISTENING" Section Header (Screenshot 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text(
                      'FRIENDS LISTENING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

                // Friends Listening Cards List (Screenshot 2)
                if (friendsListening.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161622) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'No friends currently streaming. Add a friend to start listening together!',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final friend = friendsListening[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161622) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            onTap: () => _showFriendListeningOptions(context, friend, manager),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A1F1B),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF5E3A).withOpacity(0.4),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  friend.avatarInitials.isNotEmpty ? friend.avatarInitials : '?',
                                  style: const TextStyle(
                                    color: Color(0xFFFF8E72),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                const Icon(Icons.music_note_rounded, size: 16, color: Color(0xFFFF5E3A)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${friend.currentSongTitle} - ${friend.currentSongArtist}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${friend.name} is listening now • Tap to join',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                      childCount: friendsListening.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // "SHARED PLAYLISTS / BLENDS" Section (User core requirement)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SHARED PLAYLISTS (${sharedPlaylists.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                        if (friends.isNotEmpty)
                          InkWell(
                            onTap: () => _showCreateSharedPlaylistDialog(context, friends.first, manager),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, size: 16, color: Color(0xFFFF5E3A)),
                                SizedBox(width: 2),
                                Text(
                                  'New Blend',
                                  style: TextStyle(
                                    color: Color(0xFFFF5E3A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (sharedPlaylists.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161622) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.group_rounded, color: Color(0xFFFF5E3A), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Create a Shared Playlist with Friend',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aap apne friends ke saath same song playlist bana sakte hain aur milkar gaane add/stream kar sakte hain!',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (friends.isNotEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5E3A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.queue_music_rounded, size: 18),
                                label: const Text('Create First Shared Playlist'),
                                onPressed: () => _showCreateSharedPlaylistDialog(context, friends.first, manager),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pl = sharedPlaylists[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161622) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.network(
                                    pl.coverUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: const Color(0xFF2A2016),
                                      child: const Icon(Icons.group_rounded, color: Color(0xFFFF5E3A)),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF5E3A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.sync_rounded, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pl.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5E3A).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Shared',
                                    style: TextStyle(
                                      color: Color(0xFFFF5E3A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${pl.songs.length} songs • ${pl.collaboratorNames.join(' & ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaylistDetailScreen(playlist: pl),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: sharedPlaylists.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // "ALL FRIENDS (X)" Section Header (Screenshot 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text(
                      'ALL FRIENDS (${friends.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

                // All Friends List (Screenshot 2)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final friend = friends[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161622) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A1F1B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF5E3A).withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                friend.initials,
                                style: const TextStyle(
                                  color: Color(0xFFFF8E72),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            friend.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            friend.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Chat / Send Song Icon Button
                              IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                tooltip: 'Chat & Send Song',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Connected with ${friend.name} 💬'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                          onTap: () => _showFriendListeningOptions(context, friend, manager),
                        ),
                      );
                    },
                    childCount: friends.length,
                  ),
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
