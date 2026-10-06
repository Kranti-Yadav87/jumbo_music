import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import 'track_playlist_dialogs.dart';

/// Single action button for the track options grid (Start radio, Add to playlist, Copy link).
class TrackActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const TrackActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF242426),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action grid and Jumbo Mus flame badge in TrackOptionsSheet.
class TrackActionsRow extends StatelessWidget {
  final Song song;
  final MusicPlayerManager manager;

  const TrackActionsRow({super.key, required this.song, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Grid (Start radio, Add to playlist, Copy link)
        Row(
          children: [
            Expanded(
              child: TrackActionButton(
                icon: Icons.sensors_rounded,
                label: 'Start radio',
                onTap: () {
                  Navigator.pop(context);
                  manager.playSong(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Started radio based on "${song.title}"'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TrackActionButton(
                icon: Icons.playlist_add_rounded,
                label: 'Add to playlist',
                onTap: () {
                  Navigator.pop(context);
                  showAddToPlaylistSheet(context, manager, song);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TrackActionButton(
                icon: Icons.link_rounded,
                label: 'Copy link',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: song.audioUrl));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Song link copied to clipboard!'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Flame Tag: Jumbo Mus
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF242426),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(height: 4),
                Text(
                  'Jumbo Mus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
