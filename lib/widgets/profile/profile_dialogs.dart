import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/music_player_manager.dart';
import '../../screens/auth_gate.dart';
import '../../screens/playlist_detail_screen.dart';

/// Informational banner shown when in guest mode.
class GuestModeBanner extends StatelessWidget {
  const GuestModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF818CF8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Guest mode - data stays on this device and is cleared on logout. Log out and sign in to sync.',
              style: TextStyle(
                color: Color(0xFFC7D2FE),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog for logging out.
void showProfileLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Log Out',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Text(
        DatabaseService.instance.isGuest
            ? 'You are in guest mode. Logging out will clear your guest favorites, playlists and downloads from this device.'
            : 'Are you sure you want to sign out? Your offline cached songs and playlists will remain saved on this device.',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5E3A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await AuthService.instance.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            }
          },
          child: const Text(
            'Log Out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

/// Shows bottom sheet listing user's playlists.
void showProfilePlaylistsSheet(
  BuildContext context,
  MusicPlayerManager manager,
) {
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
                    Icons.queue_music_rounded,
                    color: Color(0xFFA855F7),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Playlists (${manager.playlists.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (manager.playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No custom playlists yet. Create one from the Library tab!',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: manager.playlists.length,
                    itemBuilder: (context, idx) {
                      final pl = manager.playlists[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            pl.coverUrl,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 42,
                              height: 42,
                              color: const Color(0xFF1E293B),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          pl.title,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${pl.songs.length} songs',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistDetailScreen(playlist: pl),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
