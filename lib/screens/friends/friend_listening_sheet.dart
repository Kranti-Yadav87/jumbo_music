import 'package:flutter/material.dart';
import '../../models/friend.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import '../../services/presence_service.dart';
import 'shared_playlist_dialog.dart';

class FriendListeningSheet {
  static void show(
    BuildContext context,
    Friend friend,
    MusicPlayerManager manager, {
    VoidCallback? onJamStarted,
  }) {
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
                        border: Border.all(
                          color: const Color(0xFFFF5E3A).withOpacity(0.5),
                        ),
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            friend.isListening &&
                                    friend.currentSongTitle.isNotEmpty
                                ? 'Listening to: ${friend.currentSongTitle} • ${friend.currentSongArtist}'
                                : (friend.isOnline ? 'Online now' : 'Offline'),
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
                if (friend.isListening && friend.currentSongTitle.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E3A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: Color(0xFFFF5E3A),
                        size: 20,
                      ),
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
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      final matchingSong = manager.allSongs.firstWhere(
                        (s) =>
                            s.title.toLowerCase().contains(
                              friend.currentSongTitle.toLowerCase(),
                            ) ||
                            s.artist.toLowerCase().contains(
                              friend.currentSongArtist.toLowerCase(),
                            ),
                        orElse: () => Song(
                          id: friend.currentSongId.isNotEmpty
                              ? friend.currentSongId
                              : 'stream_${DateTime.now().millisecondsSinceEpoch}',
                          title: friend.currentSongTitle.isNotEmpty
                              ? friend.currentSongTitle
                              : 'Live Track',
                          artist: friend.currentSongArtist.isNotEmpty
                              ? friend.currentSongArtist
                              : friend.name,
                          audioUrl: manager.allSongs.isNotEmpty
                              ? manager.allSongs.first.audioUrl
                              : '',
                          coverUrl: friend.currentSongCover.isNotEmpty
                              ? friend.currentSongCover
                              : 'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
                          duration: const Duration(seconds: 210),
                        ),
                      );
                      manager.playSong(matchingSong);
                      onJamStarted?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🎧 Live Synced with ${friend.name}! Playing "${friend.currentSongTitle}"',
                          ),
                          backgroundColor: const Color(0xFFFF5E3A),
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
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: Color(0xFFA855F7),
                      size: 20,
                    ),
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
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    SharedPlaylistDialog.showCreateDialog(
                      context,
                      friend,
                      manager,
                    );
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
                      child: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
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
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sent "${manager.currentSong!.title}" to ${friend.name} 🎵',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),

                // 4. Remove Friend
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_remove_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Remove Friend',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Remove ${friend.name} from your friends list',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: isDark
                            ? const Color(0xFF1C1C24)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: const [
                            Icon(
                              Icons.person_remove_rounded,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 10),
                            Text('Remove Friend?'),
                          ],
                        ),
                        content: Text(
                          'Are you sure you want to remove ${friend.name} (${friend.email}) from your friends list?',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogCtx);
                              await PresenceService.instance.removeFriend(
                                friend.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Removed ${friend.name} from friends.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Text('Remove'),
                          ),
                        ],
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
}
