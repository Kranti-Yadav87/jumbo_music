import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import 'equalizer_bars.dart';
import 'track_options_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  double? _dragValue;

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatQueueDuration(List<Song> songs) {
    int totalSec = 0;
    for (final s in songs) {
      totalSec += s.duration.inSeconds > 0 ? s.duration.inSeconds : 210;
    }
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
  }

  void _showSleepTimerDialog(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sleep Timer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (manager.isSleepTimerActive)
                      Text(
                        manager.formattedSleepTime,
                        style: const TextStyle(
                          color: Color(0xFF80C8DE),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSleepTimerOption(ctx, manager, '15 Minutes', 15),
                    _buildSleepTimerOption(ctx, manager, '30 Minutes', 30),
                    _buildSleepTimerOption(ctx, manager, '45 Minutes', 45),
                    _buildSleepTimerOption(ctx, manager, '60 Minutes', 60),
                    _buildSleepTimerOption(ctx, manager, 'End of Song', -1),
                    if (manager.isSleepTimerActive)
                      ActionChip(
                        backgroundColor: Colors.redAccent.withOpacity(0.15),
                        label: const Text('Turn Off Timer', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          manager.cancelSleepTimer();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sleep timer cancelled')),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepTimerOption(BuildContext ctx, MusicPlayerManager manager, String label, int minutes) {
    return ActionChip(
      backgroundColor: Colors.white.withOpacity(0.08),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: () {
        if (minutes == -1) {
          manager.setSleepTimerAfterSong();
        } else {
          manager.setSleepTimer(Duration(minutes: minutes));
        }
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set: $label'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showLyricsSheet(BuildContext context, MusicPlayerManager manager, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101015),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return AnimatedBuilder(
              animation: manager,
              builder: (context, _) {
                final currentPos = manager.position;
                final totalDur = manager.duration.inSeconds > 0
                    ? manager.duration
                    : song.duration;
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.lyrics_rounded, color: Color(0xFF80C8DE), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Synced Lyrics • ${song.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white60),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    Expanded(
                      child: CustomScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildSyncedLyricsSliver(context, manager, song, currentPos, totalDur),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final song = manager.currentSong;

        if (song == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF000000),
            body: Center(
              child: Text(
                'No song playing',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        final isFav = manager.isFavorite(song.id);
        final currentPos = manager.position;
        final totalDur = manager.duration.inSeconds > 0
            ? manager.duration
            : song.duration;
        final queue = manager.queue;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: Stack(
            children: [
              // 1. Top Section: Header & 16:9 Letterbox Video/Artwork Preview (Screenshots 3 & 5)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text(
                                    'Now Playing',
                                    style: TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${song.title} | ${song.artist}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.lyrics_outlined, color: Colors.white70, size: 22),
                              tooltip: 'Synced Lyrics',
                              onPressed: () => _showLyricsSheet(context, manager, song),
                            ),
                            IconButton(
                              icon: Icon(
                                manager.isSleepTimerActive ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                                color: manager.isSleepTimerActive ? const Color(0xFF80C8DE) : Colors.white70,
                                size: 22,
                              ),
                              onPressed: () => _showSleepTimerDialog(context, manager),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                              onPressed: () => TrackOptionsSheet.show(context, song),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 16:9 Letterbox Preview Container (Screenshot 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  song.coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1C1C1E),
                                    child: const Icon(Icons.music_note, color: Colors.white30, size: 60),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                ),
                                // Audio Quality Tag
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        EqualizerBars(
                                          isPlaying: manager.isPlaying,
                                          color: const Color(0xFF80C8DE),
                                          height: 12,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          song.quality,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Progress Slider & Timers
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                activeTrackColor: const Color(0xFF80C8DE),
                                inactiveTrackColor: const Color(0xFF2C2C2E),
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                min: 0.0,
                                max: max(1.0, totalDur.inMilliseconds.toDouble()),
                                value: (_dragValue ?? currentPos.inMilliseconds.toDouble()).clamp(
                                  0.0,
                                  max(1.0, totalDur.inMilliseconds.toDouble()),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _dragValue = val;
                                  });
                                },
                                onChangeEnd: (val) {
                                  manager.seek(Duration(milliseconds: val.toInt()));
                                  setState(() {
                                    _dragValue = null;
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTime(currentPos),
                                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                                  ),
                                  Text(
                                    _formatTime(totalDur),
                                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Pull-Up Bottom Queue Sheet (Screenshots 3 & 5)
              DraggableScrollableSheet(
                initialChildSize: 0.58,
                minChildSize: 0.42,
                maxChildSize: 0.94,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF000000),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 20,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Drag Handle
                        SliverToBoxAdapter(
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),

                        // Queue Mini Header (Screenshot 3 & 5)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    song.coverUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF8E8E93),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? const Color(0xFFE5A5A5) : Colors.white70,
                                  ),
                                  onPressed: () => manager.toggleFavorite(song.id),
                                ),
                                IconButton(
                                  icon: Icon(
                                    manager.isQueueLocked
                                        ? Icons.lock_rounded
                                        : Icons.lock_outline_rounded,
                                    color: manager.isQueueLocked
                                        ? const Color(0xFF80C8DE)
                                        : Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    manager.toggleQueueLock();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          manager.isQueueLocked
                                              ? 'Queue locked - auto additions paused'
                                              : 'Queue unlocked',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                                  onPressed: () => TrackOptionsSheet.show(context, song),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Control Buttons Row (Shuffle, Repeat, Cyan Autoplay Pill) (Screenshots 3 & 5)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                // Shuffle
                                Expanded(
                                  child: InkWell(
                                    onTap: () => manager.toggleShuffle(),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: manager.isShuffle
                                            ? const Color(0xFF38383A)
                                            : const Color(0xFF242426),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.shuffle_rounded,
                                        color: manager.isShuffle ? const Color(0xFF80C8DE) : Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Repeat
                                Expanded(
                                  child: InkWell(
                                    onTap: () => manager.toggleLoopMode(),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: manager.loopMode != LoopMode.off
                                            ? const Color(0xFF38383A)
                                            : const Color(0xFF242426),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        manager.loopMode == LoopMode.one
                                            ? Icons.repeat_one_rounded
                                            : Icons.repeat_rounded,
                                        color: manager.loopMode != LoopMode.off
                                            ? const Color(0xFF80C8DE)
                                            : Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Cyan Infinite Autoplay Button (Screenshots 3 & 5)
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      manager.toggleAutoplay();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            manager.autoplay
                                                ? 'Infinite Autoplay active - Endless music enabled'
                                                : 'Autoplay turned off',
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: manager.autoplay
                                            ? const Color(0xFF80C8DE)
                                            : const Color(0xFF242426),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.all_inclusive_rounded,
                                        color: manager.autoplay ? const Color(0xFF00364A) : Colors.white60,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Queue Info Row: Continue Playing | Autoplaying similar music | 51 songs • 2h 48m 40s
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Continue Playing',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      manager.autoplay
                                          ? 'Autoplaying similar music'
                                          : 'Playing current queue',
                                      style: const TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${queue.length} songs',
                                      style: const TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatQueueDuration(queue),
                                      style: const TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Queue Song List
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = queue[index];
                              final isCurrent = manager.currentIndex == index;

                              if (isCurrent) {
                                // Active Song in Cyan Container (Screenshots 3 & 5)
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C384B),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    leading: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            item.coverUrl,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: EqualizerBars(
                                            isPlaying: manager.isPlaying,
                                            color: Colors.white,
                                            height: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.artist} • ${item.formattedDuration}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF80C8DE),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                                      onPressed: () => TrackOptionsSheet.show(context, item),
                                    ),
                                    onTap: () => manager.togglePlay(),
                                  ),
                                );
                              }

                              // Standard Upcoming Queue Item
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.coverUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 44,
                                        height: 44,
                                        color: const Color(0xFF1C1C1E),
                                        child: const Icon(Icons.music_note, color: Colors.white30),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item.artist} • ${item.formattedDuration}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                                    onPressed: () => TrackOptionsSheet.show(context, item),
                                  ),
                                  onTap: () => manager.playSong(item),
                                ),
                              );
                            },
                            childCount: queue.length,
                          ),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 40),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncedLyricsSliver(
    BuildContext context,
    MusicPlayerManager manager,
    Song song,
    Duration currentPos,
    Duration totalDur,
  ) {
    final rawLyrics = song.lyrics.trim();
    final lines = rawLyrics.isNotEmpty
        ? rawLyrics.split('\n').where((l) => l.trim().isNotEmpty).toList()
        : <String>[
            '♪ Instrumental intro ♪',
            song.title,
            'Performed by ${song.artist}',
            '320 kbps Live Studio Master',
            'Live synchronized playback active',
            '♪ Melodic transition ♪',
            'Endless music with Jumbo Autoplay',
            'Tap any line to seek track',
          ];

    final progress = totalDur.inMilliseconds > 0
        ? (currentPos.inMilliseconds / totalDur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final activeIndex = (progress * lines.length).floor().clamp(0, lines.length - 1);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final line = lines[index];
            final isCurrent = index == activeIndex;
            final isPast = index < activeIndex;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                final targetFraction = index / lines.length;
                final targetMs = (targetFraction * totalDur.inMilliseconds).toInt();
                manager.seek(Duration(milliseconds: targetMs));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF0C384B).withOpacity(0.85)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isCurrent
                      ? Border.all(color: const Color(0xFF80C8DE).withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  children: [
                    if (isCurrent) ...[
                      EqualizerBars(
                        isPlaying: manager.isPlaying,
                        color: const Color(0xFF80C8DE),
                        height: 14,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        line,
                        style: TextStyle(
                          color: isCurrent
                              ? const Color(0xFF80C8DE)
                              : isPast
                                  ? Colors.white70
                                  : Colors.white30,
                          fontSize: isCurrent ? 17 : 15,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: lines.length,
        ),
      ),
    );
  }
}
