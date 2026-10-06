import 'package:flutter/material.dart';
import '../../services/music_player_manager.dart';

/// Shows the guide and offline help dialog.
void showLibraryHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF131D31),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.help_outline_rounded, color: Color(0xFF38BDF8)),
          SizedBox(width: 10),
          Text(
            'Library & Offline Guide',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• Playlists: Create and organize custom and shared blends.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            '• Recently Played: Track all previously listened tracks.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            '• Favorites: One-tap access to all liked songs.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            '• Cached/Offline: Plays stored stream cache without internet.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            '• Downloads: 320 kbps offline master tracks saved permanently.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Got it',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

/// Shows dialog for creating a new playlist.
void showCreatePlaylistDialog(
  BuildContext context,
  MusicPlayerManager manager,
) {
  final titleController = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131D31) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'New Playlist',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: titleController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                manager.createPlaylist(title, description: 'Custom Collection');
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

/// Shows modal bottom sheet for Library View and Sorting options.
void showLibraryOptionsSheet(
  BuildContext context,
  MusicPlayerManager manager, {
  required bool isAscending,
  required ValueChanged<bool> onSortChanged,
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
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF38BDF8),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Library View & Sorting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.sort_by_alpha_rounded,
                  color: Color(0xFF38BDF8),
                ),
                title: Text(
                  isAscending
                      ? 'Sorting: A to Z (Ascending)'
                      : 'Sorting: Z to A (Descending)',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Tap to toggle sorting direction',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Icon(
                  isAscending
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: const Color(0xFF38BDF8),
                ),
                onTap: () {
                  onSortChanged(!isAscending);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.add_box_rounded,
                  color: Color(0xFF10B981),
                ),
                title: Text(
                  'Create New Playlist',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Build your own custom playlist collection',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showCreatePlaylistDialog(context, manager);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFA855F7),
                ),
                title: Text(
                  'Storage Guide & Offline Help',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Learn about cache vs permanent downloads',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showLibraryHelpDialog(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
