import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import '../cover_image.dart';

/// Modal bottom sheet for adding a song to existing or new playlist.
void showAddToPlaylistSheet(
  BuildContext context,
  MusicPlayerManager manager,
  Song song,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141416),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add to Playlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showCreatePlaylistDialogForTrack(
                        context,
                        manager,
                        addSong: song,
                      );
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Color(0xFFE5A5A5),
                    ),
                    label: const Text(
                      'New',
                      style: TextStyle(
                        color: Color(0xFFE5A5A5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (manager.playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No playlists yet. Tap "New" above to create one!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: manager.playlists.length,
                    itemBuilder: (_, index) {
                      final pl = manager.playlists[index];
                      final alreadyIn = pl.songIds.contains(song.id);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CoverImage(
                          imageUrl: pl.coverUrl,
                          width: 42,
                          height: 42,
                          borderRadius: BorderRadius.circular(8),
                          fallbackBgColor: const Color(0xFF2C2C2E),
                          fallbackIcon: Icons.queue_music,
                        ),
                        title: Text(
                          pl.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          alreadyIn
                              ? 'Already added • ${pl.songIds.length} songs'
                              : '${pl.songIds.length} songs',
                          style: TextStyle(
                            color: alreadyIn
                                ? const Color(0xFF10B981)
                                : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          alreadyIn
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          color: alreadyIn
                              ? const Color(0xFF10B981)
                              : Colors.white54,
                          size: 22,
                        ),
                        onTap: () {
                          if (!alreadyIn) {
                            manager.addSongToPlaylist(pl.id, song.id);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added "${song.title}" to ${pl.title}',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"${song.title}" is already in ${pl.title}',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

/// Dialog for creating a new playlist directly from TrackOptionsSheet.
void showCreatePlaylistDialogForTrack(
  BuildContext context,
  MusicPlayerManager manager, {
  Song? addSong,
}) {
  final titleController = TextEditingController();
  showDialog(
    context: context,
    builder: (dCtx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Playlist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A5A5),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final newPl = await manager.createPlaylist(
                  title,
                  description: 'Custom Collection',
                );
                if (addSong != null) {
                  await manager.addSongToPlaylist(newPl.id, addSong.id);
                }
                if (context.mounted) {
                  Navigator.pop(dCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Created playlist "$title"${addSong != null ? ' and added "${addSong.title}"' : ''}',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
