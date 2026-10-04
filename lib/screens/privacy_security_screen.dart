import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/privacy_security_service.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  void _showDeleteAccountDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Delete Account & Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest
                        ? 'This will permanently wipe all your local guest favorites, playlists, downloads, and listening history.'
                        : 'This will permanently delete your Jumbo Music cloud account, your Firestore profile, all synchronized playlists, favorites, history, and local downloads. This action cannot be undone.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  if (!isGuest &&
                      user.providerData.any(
                        (p) => p.providerId == 'password',
                      )) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Enter your password to confirm deletion:',
                      style: TextStyle(color: Colors.white60, fontSize: 12.5),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF14141E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage ?? '',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() {
                          isDeleting = true;
                          errorMessage = null;
                        });

                        try {
                          AuthCredential? reauthCred;
                          if (user != null &&
                              passwordController.text.isNotEmpty) {
                            reauthCred = EmailAuthProvider.credential(
                              email: user.email ?? '',
                              password: passwordController.text.trim(),
                            );
                          }

                          await AuthService.instance.deleteAccount(
                            reauthCredential: reauthCred,
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Account and all associated data have been permanently deleted.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() {
                              isDeleting = false;
                              errorMessage = AuthService.formatAuthError(e);
                            });
                          }
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Delete Permanently',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final privacy = PrivacySecurityService();
    final playerManager = MusicPlayerManager();
    final downloadService = DownloadService();
    final db = DatabaseService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([
        privacy,
        playerManager,
        downloadService,
        db,
      ]),
      builder: (context, _) {
        final isUserLoggedIn = db.isLoggedIn && !db.userEmail.contains('guest');

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
              // 1. Top Shield Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF064E3B),
                      Color(0xFF042F2E),
                      Color(0xFF021715),
                    ],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Privacy is Our #1 Priority',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUserLoggedIn
                                ? 'Your profile and playlists are securely isolated to your account in Firebase Cloud Firestore. Zero ad trackers or third-party data selling.'
                                : 'You are in Guest Mode. All playback data and preferences remain strictly local to your device.',
                            style: const TextStyle(
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
                          color: privacy.isIncognitoMode
                              ? const Color(0xFF10B981)
                              : Colors.white60,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Incognito Private Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Do not record listening history or search queries while playing.',
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
                        'Scoped Account Storage',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Active Scope: ${db.currentScope}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Isolated',
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Disabled by default for 100% privacy. No personal data shared.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      onChanged: (_) => privacy.toggleAnalytics(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Permissions Transparency
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
                    _buildPermissionRow(
                      Icons.mic_off_rounded,
                      'Microphone Access',
                      'Never Requested / Blocked',
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRow(
                      Icons.videocam_off_rounded,
                      'Camera Access',
                      'Never Requested / Blocked',
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRow(
                      Icons.location_off_rounded,
                      'Location Tracking',
                      'Never Requested / Blocked',
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRow(
                      Icons.contacts_rounded,
                      'Contacts & Social',
                      'Never Requested / Blocked',
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRow(
                      Icons.sd_storage_rounded,
                      'Offline Storage',
                      'Scoped Only to Downloaded Audio',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Data Management & Rights
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
                      leading: const Icon(
                        Icons.history_rounded,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        'Clear Listening History',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Erase all recently played tracks from active scope',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white30,
                      ),
                      onTap: () {
                        playerManager.clearPlaybackHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Listening history wiped successfully.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1, color: Color(0xFF242426)),

                    // Delete All Data & Account
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        isUserLoggedIn
                            ? 'Delete Account & Cloud Data'
                            : 'Reset Local Guest Data',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        isUserLoggedIn
                            ? 'Permanently delete Firebase user, Firestore docs & local data'
                            : 'Wipe local favorites, downloads, playlists, and history',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () => _showDeleteAccountDialog(context),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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
