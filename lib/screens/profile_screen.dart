import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/music_player_manager.dart';
import '../widgets/app_top_header.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/auth_dialog.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/downloaded_songs_screen.dart';
import '../screens/privacy_security_screen.dart';
import '../models/playlist.dart';

class ProfileScreen extends StatelessWidget {
  final bool showHeader;

  const ProfileScreen({super.key, this.showHeader = true});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out? Your offline cached songs and playlists will remain saved on this device.',
          style: TextStyle(color: Colors.white70),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              }
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final likedCount = manager.favoriteSongs.length;
        final playlistCount = manager.playlists.length;
        final historyCount = manager.recentlyPlayed.length;
        final hoursPlayed = historyCount > 0 ? '${(historyCount * 0.4).toStringAsFixed(1)}h' : '—';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF101016) : const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              // Top Warm Gradient Glow matching Screenshot 1
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 280,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF5A2A1A).withOpacity(0.65),
                              const Color(0xFF381B14).withOpacity(0.35),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFFFE4D6),
                              const Color(0xFFFFF0EA),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),

              // Main Scrollable Content
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                    // Top App Header
                    if (showHeader)
                      const SliverToBoxAdapter(
                        child: AppTopHeader(title: 'Jumbo Music'),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Profile Avatar Section with camera badge (Screenshot 1)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Large Monogram Circular Avatar
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFF2A2016),
                                        Color(0xFF1A140E),
                                        Color(0xFF0F0B08),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withOpacity(0.35),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      db.userInitials,
                                      style: const TextStyle(
                                        fontFamily: 'serif',
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                        color: Color(0xFFFFD700),
                                        shadows: [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Camera / Edit Icon Badge (Orange Circle in bottom right)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => EditProfileDialog.show(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5E3A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF101016) : Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF5E3A).withOpacity(0.4),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Display Name
                          Text(
                            db.userName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Email
                          Text(
                            db.userEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Jumbo User ID Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF818CF8)),
                                const SizedBox(width: 6),
                                Text(
                                  'ID: ${db.userId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF818CF8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.cloud_done_rounded, size: 12, color: Color(0xFF10B981)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Cloud Sync',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // "Edit Profile" and "Sign In / Switch" Buttons
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5E3A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                label: const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => EditProfileDialog.show(context),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  side: BorderSide(
                                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                icon: Icon(
                                  db.isLoggedIn ? Icons.swap_horiz_rounded : Icons.login_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  db.isLoggedIn ? 'Switch ID' : 'Sign In / Register',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => AuthDialog.show(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // 3 Metric / Stats Cards Row (Liked Songs, Playlists, Hours Played)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // 1. Liked Songs
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.favorite_border_rounded,
                                iconColor: const Color(0xFFFF5E7E),
                                count: '$likedCount',
                                label: 'Liked Songs',
                                onTap: () {
                                  final favPlaylist = Playlist(
                                    id: 'favs',
                                    title: 'Liked Songs',
                                    description: 'Your favorite collection',
                                    coverUrl: manager.favoriteSongs.isNotEmpty
                                        ? manager.favoriteSongs.first.coverUrl
                                        : 'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
                                    songIds: manager.favoriteIds.toList(),
                                    songs: manager.favoriteSongs,
                                    type: PlaylistType.favorites,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: favPlaylist)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 2. Playlists
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.music_note_rounded,
                                iconColor: const Color(0xFFA855F7),
                                count: '$playlistCount',
                                label: 'Playlists',
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 3. Hours Played
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.access_time_rounded,
                                iconColor: const Color(0xFF38BDF8),
                                count: hoursPlayed,
                                label: 'Hours Played',
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ACCOUNT Section Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'ACCOUNT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),

                    // Log Out Card (Screenshot 1)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161622) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4B2B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFFF5E3A),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Log Out',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Sign out of your account',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ),
                    ),

                    // Additional Options: Downloaded Songs
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161622) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.download_done_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Offline Vault',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Manage downloaded & cached music',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              fontSize: 12,
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
                              MaterialPageRoute(builder: (_) => const DownloadedSongsScreen()),
                            );
                          },
                        ),
                      ),
                    ),

                    // Privacy & Security
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161622) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF6366F1),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Privacy & Security',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Incognito mode, local data wipe',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              fontSize: 12,
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
                              MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                            );
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161622) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
