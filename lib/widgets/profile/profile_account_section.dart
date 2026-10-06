import 'package:flutter/material.dart';
import '../../screens/downloaded_songs_screen.dart';
import '../../screens/privacy_security_screen.dart';
import '../../screens/feedback_screen.dart';
import 'profile_dialogs.dart';

/// Account section items in ProfileScreen (Log Out, Offline Vault, Privacy & Security, Feedback).
class ProfileAccountSection extends StatelessWidget {
  final bool isDark;

  const ProfileAccountSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ACCOUNT Section Header
        Padding(
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

        // Log Out Card
        _buildAccountCard(
          isDark: isDark,
          iconBg: const Color(0xFFFF4B2B).withOpacity(0.12),
          icon: Icons.logout_rounded,
          iconColor: const Color(0xFFFF5E3A),
          title: 'Log Out',
          subtitle: 'Sign out of your account',
          onTap: () => showProfileLogoutDialog(context),
        ),

        // Offline Vault
        _buildAccountCard(
          isDark: isDark,
          iconBg: const Color(0xFF10B981).withOpacity(0.12),
          icon: Icons.download_done_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Offline Vault',
          subtitle: 'Manage downloaded & cached music',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadedSongsScreen()),
            );
          },
        ),

        // Privacy & Security
        _buildAccountCard(
          isDark: isDark,
          iconBg: const Color(0xFF6366F1).withOpacity(0.12),
          icon: Icons.security_rounded,
          iconColor: const Color(0xFF6366F1),
          title: 'Privacy & Security',
          subtitle: 'Incognito mode, local data wipe',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
            );
          },
        ),

        // App Feedback & Rating
        _buildAccountCard(
          isDark: isDark,
          iconBg: const Color(0xFFFF5E3A).withOpacity(0.12),
          icon: Icons.star_rate_rounded,
          iconColor: const Color(0xFFFF5E3A),
          title: 'App Feedback & Rating',
          subtitle: 'Rate 5 stars, request songs & report issues',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountCard({
    required bool isDark,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
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
        onTap: onTap,
      ),
    );
  }
}
