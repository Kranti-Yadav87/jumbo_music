import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiveJamDialog {
  static void show(
    BuildContext context, {
    required String roomCode,
    required bool isLiveJamActive,
    required ValueChanged<bool> onJamToggled,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF181824) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.podcasts_rounded, color: Color(0xFFFF5E3A)),
            SizedBox(width: 10),
            Text(
              'Live Synced Jam Room',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this Room Code with your friend. When they join, both devices will play the exact same song and pause/seek in sync!',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF5E3A).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.key_rounded,
                    size: 18,
                    color: Color(0xFFFF5E3A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      roomCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Color(0xFFFF5E3A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room Code copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5E3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.sensors_rounded, size: 18),
            label: Text(isLiveJamActive ? 'Leave Jam' : 'Start Live Session'),
            onPressed: () {
              final newState = !isLiveJamActive;
              onJamToggled(newState);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newState
                        ? '🎧 Live Jam Room $roomCode is ACTIVE! Both devices will play together.'
                        : 'Left Live Jam room.',
                  ),
                  backgroundColor: const Color(0xFFFF5E3A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
