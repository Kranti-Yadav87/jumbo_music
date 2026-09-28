import 'package:flutter/material.dart';
import '../services/music_player_manager.dart';
import '../widgets/mini_player.dart';
import 'home_tab.dart';
import 'stats_tab.dart';
import 'history_tab.dart';
import 'library_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Defaults to HomeTab

  final List<Widget> _tabs = const [
    HomeTab(),
    StatsTab(),
    HistoryTab(),
    LibraryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
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
                bottom: 64, // Positioned right above bottom navigation bar
                child: MiniPlayer(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0E),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_outlined, 'Home'),
                _buildNavItem(1, Icons.trending_up_rounded, 'Stats'),
                _buildNavItem(2, Icons.access_time_rounded, 'History'),
                _buildNavItem(3, Icons.grid_view_rounded, 'Library'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill capsule highlight around icon for active tab (Screenshot 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF563F42) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFFD4D4) : Colors.white60,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
