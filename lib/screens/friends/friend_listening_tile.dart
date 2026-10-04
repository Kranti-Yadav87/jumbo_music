import 'package:flutter/material.dart';
import '../../models/friend.dart';
import '../../services/music_player_manager.dart';
import 'friend_listening_sheet.dart';

class FriendListeningTile extends StatelessWidget {
  final Friend friend;
  final MusicPlayerManager manager;
  final VoidCallback? onJamStarted;

  const FriendListeningTile({
    super.key,
    required this.friend,
    required this.manager,
    this.onJamStarted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => FriendListeningSheet.show(
        context,
        friend,
        manager,
        onJamStarted: onJamStarted,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: friend.isListening
                ? const Color(0xFFFF5E3A).withValues(alpha: 0.3)
                : (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: friend.isListening
                          ? const [Color(0xFFFF5E3A), Color(0xFFFF2A54)]
                          : [Colors.grey.shade700, Colors.grey.shade800],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      friend.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: friend.isOnline
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF12121A) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        friend.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      if (friend.isListening) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.equalizer_rounded,
                          size: 16,
                          color: Color(0xFFFF5E3A),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.isListening && friend.currentSongTitle.isNotEmpty
                        ? '🎵 ${friend.currentSongTitle} • ${friend.currentSongArtist}'
                        : (friend.isOnline ? 'Online' : 'Offline'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: friend.isListening
                          ? const Color(0xFFFF5E3A)
                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                      fontWeight: friend.isListening
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: Colors.white54,
              ),
              onPressed: () => FriendListeningSheet.show(
                context,
                friend,
                manager,
                onJamStarted: onJamStarted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
