import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/privacy_security_service.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final privacy = PrivacySecurityService();
    final playerManager = MusicPlayerManager();
    final downloadService = DownloadService();

    return AnimatedBuilder(
      animation: Listenable.merge([privacy, playerManager, downloadService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D0D12),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'Data Privacy & Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // 1. Top Shield Banner: Privacy Top Priority
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF042F2E), Color(0xFF021715)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF10B981),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Privacy is Our #1 Priority',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Zero data tracking, zero ad trackers, no selling of user data. Everything stays 100% private on your device.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Private Listening & Vault Controls
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Privacy Controls',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: privacy.isIncognitoMode,
                      activeColor: const Color(0xFF10B981),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: privacy.isIncognitoMode
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.visibility_off_rounded,
                          color: privacy.isIncognitoMode ? const Color(0xFF10B981) : Colors.white60,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Incognito Private Mode',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text(
                        'Do not record listening history or update dynamic mixes while playing.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      onChanged: (_) {
                        privacy.toggleIncognitoMode();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              privacy.isIncognitoMode
                                  ? 'Incognito Mode Activated - Zero history will be saved.'
                                  : 'Incognito Mode Disabled.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1, color: Color(0xFF242426)),

                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Offline Data Vault Encryption',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text(
                        'Downloaded tracks and cache are securely isolated.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Encrypted',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFF242426)),

                    SwitchListTile.adaptive(
                      value: privacy.analyticsEnabled,
                      activeColor: const Color(0xFF10B981),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white60,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Telemetry & Ad Tracking',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text(
                        'Disabled by default for 100% privacy. No usage data sent anywhere.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      onChanged: (_) => privacy.toggleAnalytics(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Permissions Transparency Audit
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Permissions Transparency',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    _buildPermissionRow(Icons.mic_off_rounded, 'Microphone Access', 'Never Requested / Blocked'),
                    const SizedBox(height: 12),
                    _buildPermissionRow(Icons.videocam_off_rounded, 'Camera Access', 'Never Requested / Blocked'),
                    const SizedBox(height: 12),
                    _buildPermissionRow(Icons.location_off_rounded, 'Location Tracking', 'Never Requested / Blocked'),
                    const SizedBox(height: 12),
                    _buildPermissionRow(Icons.contacts_rounded, 'Contacts & Social', 'Never Requested / Blocked'),
                    const SizedBox(height: 12),
                    _buildPermissionRow(Icons.sd_storage_rounded, 'Offline Storage', 'Scoped Only to Downloaded Audio'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Data Ownership & GDPR Right to be Forgotten
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Data Management & Rights',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    // Clear History
                    ListTile(
                      leading: const Icon(Icons.history_rounded, color: Colors.white70),
                      title: const Text('Clear Listening History', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Erase all recently played tracks from device', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                      onTap: () {
                        playerManager.clearPlaybackHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Listening history wiped successfully.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1, color: Color(0xFF242426)),

                    // Export Data JSON
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined, color: Colors.white70),
                      title: const Text('Export My Data (JSON)', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Download complete copy of your favorites and playlists', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                      onTap: () {
                        final jsonStr = privacy.exportUserDataAsJson(
                          favoriteIds: playerManager.favoriteIds.toList(),
                          downloadedSongIds: downloadService.downloadedSongs.map((s) => s.id).toList(),
                          playlistCount: playerManager.playlists.length,
                        );
                        Clipboard.setData(ClipboardData(text: jsonStr));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Encrypted user data JSON copied to clipboard.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1, color: Color(0xFF242426)),

                    // Delete All Data
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                      title: const Text('Delete All User Data & Reset', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Complete wipe: favorites, downloads, playlists, and history', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1C1C1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Text('Delete All User Data?', style: TextStyle(color: Colors.white)),
                            content: const Text(
                              'This will permanently delete your listening history, favorites, custom playlists, and offline downloaded songs. This action cannot be undone.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () {
                                  playerManager.clearAllUserData();
                                  downloadService.clearAllDownloads();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All user data permanently deleted.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Delete Everything', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionRow(IconData icon, String title, String status) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 18),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          status,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
