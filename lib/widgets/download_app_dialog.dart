import 'package:flutter/material.dart';
import '../services/pwa_install_helper.dart';

/// Shows the Download & Install App modal dialog or bottom sheet
Future<void> showDownloadAppDialog(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101015),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _DownloadAppContent(isBottomSheet: true),
    );
  }

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF101015),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: const _DownloadAppContent(isBottomSheet: false),
      ),
    ),
  );
}

class _DownloadAppContent extends StatefulWidget {
  final bool isBottomSheet;
  const _DownloadAppContent({required this.isBottomSheet});

  @override
  State<_DownloadAppContent> createState() => _DownloadAppContentState();
}

class _DownloadAppContentState extends State<_DownloadAppContent> {
  bool _isInstalling = false;

  Future<void> _handleDirectInstall() async {
    setState(() => _isInstalling = true);

    try {
      final installed = await triggerPwaInstall();
      if (!mounted) return;

      if (installed) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('App install initiated successfully!'),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E1E26),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            content: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF818CF8)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use the platform steps below (⋮ in Chrome or Share in Safari) to install on your home screen.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF262630),
          content: Text(
            'Follow the instructions below to add to your Home Screen.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isInstalling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          widget.isBottomSheet ? 12 : 22,
          20,
          widget.isBottomSheet ? 28 : 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet handle if bottom sheet
            if (widget.isBottomSheet) ...[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Brand Icon Emblem
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Download Jumbo Music',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Progressive Web App (PWA) & APK',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white60,
                    size: 22,
                  ),
                  splashRadius: 18,
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Description
            const Text(
              'Install Jumbo Music on your device for instant 1-tap music streaming, ultra-fast performance, offline caching, and lock-screen background playback.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons: 1. Download APK, 2. 1-Tap Web App Install
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  downloadFile(
                    'https://github.com/Kranti-Yadav87/jumbo_music/releases/latest/download/app-release.apk',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF064E3B),
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          Icon(Icons.downloading_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Downloading Jumbo Music Android APK (v2.0.0 Pro)...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.android_rounded, size: 22),
                label: const Text(
                  'Download Android App (APK)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Direct 1-Tap Install Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isInstalling ? null : _handleDirectInstall,
                icon: _isInstalling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.install_mobile_rounded, size: 22),
                label: Text(
                  _isInstalling
                      ? 'Installing Jumbo Music...'
                      : '1-Tap Add Web App (PWA)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Platform Instruction Cards (matching REC MedAssist style)
            _buildPlatformCard(
              icon: '📱',
              title: 'Android (Chrome / Edge / Samsung)',
              instructions:
                  'Tap the ⋮ menu at top right → select "Install app" or "Add to Home screen".',
            ),
            const SizedBox(height: 9),
            _buildPlatformCard(
              icon: '🍎',
              title: 'iPhone / iPad (iOS Safari)',
              instructions:
                  'Tap the Share button (⎋) at the bottom → select "Add to Home Screen" (➕).',
            ),
            const SizedBox(height: 9),
            _buildPlatformCard(
              icon: '💻',
              title: 'Desktop (Chrome, Edge, Brave, Mac)',
              instructions:
                  'Click the Install icon (⊕) in the browser address bar for desktop app access.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard({
    required String icon,
    required String title,
    required String instructions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20, height: 1.2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  instructions,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    height: 1.35,
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
