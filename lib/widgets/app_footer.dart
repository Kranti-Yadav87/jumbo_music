import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../screens/privacy_security_screen.dart';
import 'download_app_dialog.dart';
import 'install_app_card.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  void _showTermsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF14141E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Jumbo Music • Free & Open Streaming',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermsSection(
                          title: '1. Free Non-Commercial Use',
                          content:
                              'Jumbo Music is provided free of charge for personal, non-commercial entertainment. We do not sell subscriptions, display ads, or charge users.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildTermsSection(
                          title: '2. Content & Fair Use',
                          content:
                              'All music audio streams, metadata, and album artwork are fetched via public APIs and CDN endpoints under fair use and educational streaming principles. Intellectual property rights belong to their respective record labels, artists, and creators.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildTermsSection(
                          title: '3. Privacy & Offline Cache',
                          content:
                              'Jumbo Music stores user preferences, favorites, and playlists strictly on your local device. We never sell or transfer your personal data.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildTermsSection(
                          title: '4. Limitation of Liability',
                          content:
                              'The streaming service is provided "as is" without warranties of uninterrupted uptime. We reserve the right to update or enhance features to protect audio fidelity and user safety.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'I Understand & Agree',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = AppThemeManager.instance;
    final isDark = themeManager.isDarkMode;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // 1. Relocated App Download & Install Banner
          const InstallAppCard(
            margin: EdgeInsets.only(bottom: 20),
          ),

          // 2. Footer Container Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101018) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Row: App Logo, Tagline & Theme Mode Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JUMBO MUSIC',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Live 320kbps Music Streaming',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Quick Theme Toggle Chip
                    InkWell(
                      onTap: () => themeManager.toggleTheme(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              size: 14,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDark ? 'Lite' : 'Dark',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 16),

                // Legal & Action Links Row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    // Download App Button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text(
                        'Download App',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => showDownloadAppDialog(context),
                    ),

                    // Privacy Policy Button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.shield_outlined, size: 16),
                      label: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                        );
                      },
                    ),

                    // Terms of Service Button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.gavel_rounded, size: 16),
                      label: const Text(
                        'Terms',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _showTermsDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Signature: "Made with love by Kranti"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Made with ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const Text(
                      '❤️',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      ' by ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                      ).createShader(bounds),
                      child: const Text(
                        'Kranti',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  'v2.4 Pro • All Rights Reserved © 2026',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
