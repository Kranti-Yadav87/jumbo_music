import 'package:flutter/material.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import '../widgets/track_options_sheet.dart';
import '../widgets/mini_player.dart';
import '../widgets/cover_image.dart';

class CachedOfflineScreen extends StatelessWidget {
  const CachedOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final downloadService = DownloadService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        final downloadedSongs = downloadService.downloadedSongs;
        final historySongs = manager.recentlyPlayed;
        // All songs available for 100% offline / cached playback
        final offlineSongs = {...downloadedSongs, ...historySongs}.toList();

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0A0F1D)
              : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Cached & Offline Audio',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          bottomNavigationBar: manager.currentSong != null
              ? const SafeArea(top: false, child: MiniPlayer())
              : null,
          body: SafeArea(
            child: Column(
              children: [
                // Airplane / Offline Banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D31) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E2D4A)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flight_takeoff_rounded,
                          color: Color(0xFF0EA5E9),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Airplane Mode & Zero Internet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${offlineSongs.length} tracks cached in memory & ready to play without WiFi or mobile data.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Offline Songs List
                Expanded(
                  child: offlineSongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 56,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No offline audio yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Play or download songs to keep them cached for offline listening.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: offlineSongs.length,
                          itemBuilder: (context, index) {
                            final song = offlineSongs[index];
                            final isCurrent =
                                manager.currentSong?.id == song.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF131D31)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xFF0EA5E9).withOpacity(0.5)
                                      : (isDark
                                            ? Colors.white.withOpacity(0.04)
                                            : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: ListTile(
                                leading: CoverImage(
                                  imageUrl: song.coverUrl,
                                  width: 46,
                                  height: 46,
                                  borderRadius: BorderRadius.circular(10),
                                  fallbackBgColor: const Color(0xFF1E293B),
                                  fallbackIcon: Icons.music_note,
                                ),
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? const Color(0xFF0EA5E9)
                                        : (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A)),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${song.artist} • Offline Ready',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF64748B),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          TrackOptionsSheet.show(context, song),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () {
                                          if (isCurrent) {
                                            manager.togglePlay();
                                          } else {
                                            manager.playSong(
                                              song,
                                              newQueue: offlineSongs,
                                            );
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            isCurrent && manager.isPlaying
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_fill,
                                            color: isCurrent
                                                ? const Color(0xFF0EA5E9)
                                                : Colors.grey.shade400,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (isCurrent) {
                                    manager.togglePlay();
                                  } else {
                                    manager.playSong(
                                      song,
                                      newQueue: offlineSongs,
                                    );
                                  }
                                },
                              ),
                            );
                          },
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
