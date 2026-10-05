import 'package:flutter/material.dart';
import '../../services/share_service.dart';

/// Top brand bar displayed in the LibraryTab (App Logo, Jumbo Music, Help, Share).
class LibraryTopBrandBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onHelpTap;

  const LibraryTopBrandBar({
    super.key,
    required this.isDark,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Jumbo Music',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              size: 22,
            ),
            tooltip: 'Help & Info',
            onPressed: onHelpTap,
          ),
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              size: 20,
            ),
            tooltip: 'Share App',
            onPressed: () => ShareService.shareApp(context),
          ),
        ],
      ),
    );
  }
}

/// Title header row for "Library" with the circular add playlist (+) button.
class LibraryTitleRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAddTap;

  const LibraryTitleRow({
    super.key,
    required this.isDark,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Library',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF263756)
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
