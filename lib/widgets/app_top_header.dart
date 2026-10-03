import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/music_player_manager.dart';
import '../services/theme_service.dart';
import '../screens/search_tab.dart';
import '../screens/profile_screen.dart';
import '../screens/privacy_security_screen.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/download_app_dialog.dart';

class AppTopHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;
  final String title;

  const AppTopHeader({
    super.key,
    this.onProfileTap,
    this.onSearchTap,
    this.title = 'Jumbo Music',
  });

  void _showSettingsSheet(BuildContext context, MusicPlayerManager manager) {
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
                      Icons.settings_outlined,
                      color: Color(0xFFFF5E3A),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Settings & Audio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: manager.autoplay,
                  activeColor: const Color(0xFFFF5E3A),
                  title: Text(
                    'Infinite Autoplay',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Keep playing related music continuously',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  onChanged: (_) {
                    manager.toggleAutoplay();
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.equalizer_rounded,
                    color: Color(0xFFFF5E3A),
                  ),
                  title: Text(
                    'Audio Quality Preset',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${manager.soundPreset} preset',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: Icon(
                    AppThemeManager.instance.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: const Color(0xFFFBBF24),
                  ),
                  title: Text(
                    AppThemeManager.instance.isDarkMode
                        ? 'Theme (Dark Mode)'
                        : 'Theme (Light Mode)',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Toggle light & dark interface',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: AppThemeManager.instance.isDarkMode,
                    activeColor: const Color(0xFFFF5E3A),
                    onChanged: (_) => AppThemeManager.instance.toggleTheme(),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF10B981),
                  ),
                  title: Text(
                    'Data Privacy & Security',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '100% Client-side. Incognito, vault, zero tracking.',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
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
                        builder: (_) => const PrivacySecurityScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.install_mobile_rounded,
                    color: Color(0xFF818CF8),
                  ),
                  title: Text(
                    'Download App (PWA & APK)',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Install on Android, iOS & PC for 1-tap playback',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
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
                    showDownloadAppDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
        final hasUnreadNotifs = db.notifications.any(
          (n) => (n['isRead'] as bool?) == false,
        );

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 1. Logo + App Name Brand
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Dark / Light mode toggle (always visible at the top)
                IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF334155),
                    size: 24,
                  ),
                  tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                  onPressed: () => AppThemeManager.instance.toggleTheme(),
                ),
                const SizedBox(width: 4),

                // 2. Search Icon
                IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    size: 24,
                  ),
                  tooltip: 'Search Songs, Artists, Playlists',
                  onPressed: () {
                    if (onSearchTap != null) {
                      onSearchTap!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchTab()),
                      );
                    }
                  },
                ),
                const SizedBox(width: 4),

                // 3. Notification Bell Icon with Badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                        size: 24,
                      ),
                      tooltip: 'Notifications',
                      onPressed: () => NotificationsSheet.show(context),
                    ),
                    if (hasUnreadNotifs)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4B2B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),

                // 4. Settings Gear Icon
                IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.settings_outlined,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    size: 24,
                  ),
                  tooltip: 'Settings & Audio',
                  onPressed: () => _showSettingsSheet(context, manager),
                ),
                const SizedBox(width: 8),

                // 5. Profile Avatar Button (Gold/Bronze Ring Monogram Avatar)
                GestureDetector(
                  onTap: () {
                    if (onProfileTap != null) {
                      onProfileTap!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFF8C6D23),
                          Color(0xFF3E2F13),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        db.userInitials,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
