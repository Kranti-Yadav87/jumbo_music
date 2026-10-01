import 'package:flutter/material.dart';
import '../services/music_player_manager.dart';
import '../widgets/mini_player.dart';
import '../widgets/now_playing_screen.dart';
import 'home_tab.dart';
import 'search_tab.dart';
import 'library_tab.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // 0: Home, 1: Search, 2: Library, 3: Settings/Profile

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeTab(onProfileTap: () => setState(() => _currentIndex = 3)),
      SearchTab(onBack: () => setState(() => _currentIndex = 0)),
      const LibraryTab(),
      const ProfileScreen(showHeader: false),
    ];
  }

  void _openNowPlaying(BuildContext context) {
    final manager = MusicPlayerManager();
    if (manager.currentSong == null && manager.allSongs.isNotEmpty) {
      manager.playSong(manager.allSongs.first);
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const NowPlayingScreen(),
        transitionsBuilder: (context, anim1, anim2, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: anim1.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBgColor = isDark ? const Color(0xFF081220) : Colors.white;
    final navBorderColor = isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Active Tab Content
          IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),

          // Docked MiniPlayer above bottom navigation
          AnimatedBuilder(
            animation: manager,
            builder: (context, _) {
              if (manager.currentSong == null) return const SizedBox.shrink();
              return const Positioned(
                left: 0,
                right: 0,
                bottom: 68, // Positioned right above bottom navigation bar
                child: MiniPlayer(),
              );
            },
          ),
        ],
      ),

      // Bottom Navigation Footer matching Screenshot 1 (Home, Search, Center Continue Play, Library, Settings)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            top: BorderSide(
              color: navBorderColor,
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Home
                _buildNavItem(
                  tabIndex: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),

                // 2. Search
                _buildNavItem(
                  tabIndex: 1,
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  label: 'Search',
                ),

                // 3. CENTER BUTTON: CONTINUE PLAY (Headphones / Play Glowing Button) - Screenshot 1
                GestureDetector(
                  onTap: () => _openNowPlaying(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.55),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        manager.isPlaying ? Icons.headphones_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF081220),
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // 4. Library (Active when _currentIndex == 2)
                _buildNavItem(
                  tabIndex: 2,
                  icon: Icons.library_music_outlined,
                  activeIcon: Icons.library_music_rounded,
                  label: 'Library',
                ),

                // 5. Settings / Profile (Active when _currentIndex == 3)
                _buildNavItem(
                  tabIndex: 3,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int tabIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == tabIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => setState(() => _currentIndex = tabIndex),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
