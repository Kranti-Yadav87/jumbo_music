import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/music_player_manager.dart';
import '../widgets/app_top_header.dart';
import '../widgets/profile/profile_avatar_header.dart';
import '../widgets/profile/profile_stats_row.dart';
import '../widgets/profile/profile_account_section.dart';
import '../widgets/profile/profile_dialogs.dart';

class ProfileScreen extends StatelessWidget {
  final bool showHeader;

  const ProfileScreen({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final manager = MusicPlayerManager();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([db, manager]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF101016)
              : const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              // Top Warm Gradient Glow
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

                        // Guest mode banner
                        if (db.isGuest)
                          const SliverToBoxAdapter(child: GuestModeBanner()),

                        const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        // Profile Avatar, User Details & Action Buttons
                        SliverToBoxAdapter(
                          child: ProfileAvatarHeader(db: db, isDark: isDark),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 28)),

                        // 3 Metric / Stats Cards Row
                        SliverToBoxAdapter(
                          child: ProfileStatsRow(manager: manager),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 28)),

                        // Account Section (Log Out, Offline Vault, Privacy, Feedback)
                        SliverToBoxAdapter(
                          child: ProfileAccountSection(isDark: isDark),
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
}
