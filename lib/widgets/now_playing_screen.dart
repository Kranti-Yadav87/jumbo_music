import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _shareSong(BuildContext context, Song song) {
    Clipboard.setData(ClipboardData(text: '${song.title} by ${song.artist} - Listen on Jumbo Music'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${song.title} - ${song.artist}" to clipboard! Ready to share.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
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
      backgroundColor: Colors.white.withValues(alpha: 0.08),
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

  void _showQueueSheet(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C0C14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return AnimatedBuilder(
              animation: manager,
              builder: (context, _) {
                final song = manager.currentSong;
                final queue = manager.queue;
                final isFav = song != null && manager.isFavorite(song.id);

                return CustomScrollView(
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

                    if (song != null)
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
                                  errorBuilder: (_, _, _) => Container(
                                    width: 44,
                                    height: 44,
                                    color: const Color(0xFF1C1C1E),
                                    child: const Icon(Icons.music_note, color: Colors.white30),
                                  ),
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
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFav ? const Color(0xFFE57373) : Colors.white70,
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

                    // Controls Row (Shuffle, Repeat, Autoplay)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: manager.isShuffle
                                    ? const Color(0xFF80C8DE)
                                    : Colors.white.withValues(alpha: 0.08),
                                foregroundColor: manager.isShuffle ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.shuffle, size: 16),
                              label: const Text('Shuffle', style: TextStyle(fontSize: 12)),
                              onPressed: () => manager.toggleShuffle(),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: manager.loopMode != LoopMode.off
                                    ? const Color(0xFF80C8DE)
                                    : Colors.white.withValues(alpha: 0.08),
                                foregroundColor: manager.loopMode != LoopMode.off ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: Icon(
                                manager.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                                size: 16,
                              ),
                              label: Text(
                                manager.loopMode == LoopMode.one ? 'Repeat 1' : 'Repeat',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => manager.toggleLoopMode(),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: manager.autoplay
                                    ? const Color(0xFF80C8DE)
                                    : Colors.white.withValues(alpha: 0.08),
                                foregroundColor: manager.autoplay ? const Color(0xFF00364A) : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.all_inclusive_rounded, size: 18),
                              label: Text(
                                manager.autoplay ? 'Autoplay On' : 'Autoplay Off',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => manager.toggleAutoplay(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: Divider(color: Colors.white12, height: 20),
                    ),

                    // Queue Info Row: Continue Playing & Autoplaying Similar Music
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      : 'Autoplay paused',
                                  style: TextStyle(
                                    color: manager.autoplay
                                        ? const Color(0xFF80C8DE)
                                        : Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${queue.length} songs • ${_formatQueueDuration(queue)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Queue List
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = queue[index];
                          final isCurrent = song != null && item.id == song.id;

                          if (isCurrent) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C384B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF80C8DE).withValues(alpha: 0.3)),
                              ),
                              child: ListTile(
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
                                        errorBuilder: (_, _, _) => Container(
                                          width: 44,
                                          height: 44,
                                          color: const Color(0xFF1C1C1E),
                                          child: const Icon(Icons.music_note, color: Colors.white30),
                                        ),
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
                                  errorBuilder: (_, _, _) => Container(
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
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
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
            backgroundColor: Color(0xFF0C0C14),
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

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            // Swiping UP opens the Queue sheet
            if (details.primaryVelocity != null && details.primaryVelocity! < -220) {
              _showQueueSheet(context, manager);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0C0C14),
            body: Stack(
              children: [
                // 1. Ambient Background Gradient (rich olive/amber dark gradient matching reference)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2E2914), // Ambient olive/bronze tint from screenshot
                          Color(0xFF16140A),
                          Color(0xFF0A0A0E),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Soft central glow
                Positioned(
                  top: 130,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF80C8DE).withValues(alpha: 0.10),
                            blurRadius: 100,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Main Player Column
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenHeight = constraints.maxHeight;
                      final screenWidth = constraints.maxWidth;
                      // Dynamic square cover size responsive to screen height
                      final maxAllowedWidth = (screenWidth - 56).clamp(190.0, 320.0);
                      final coverSize = (screenHeight * 0.36).clamp(190.0, maxAllowedWidth);

                      return Column(
                        children: [
                          // Top Bar: Down Arrow + Now Playing Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'NOW PLAYING',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.55),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        song.album.isNotEmpty ? song.album : 'Jumbo Music',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 48), // Balance spacing for down arrow
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),

                          // Large Center Cover Artwork
                          Center(
                            child: Container(
                              width: coverSize,
                              height: coverSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      song.coverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: const Color(0xFF1E1E24),
                                        child: const Icon(
                                          Icons.music_note_rounded,
                                          color: Colors.white30,
                                          size: 70,
                                        ),
                                      ),
                                    ),
                                    // Quality Badge on bottom left
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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

                          const Spacer(flex: 1),

                          // Track Title, Artist, Share, and Heart Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share_outlined,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  tooltip: 'Share',
                                  onPressed: () => _shareSong(context, song),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? const Color(0xFFE57373) : Colors.white70,
                                    size: 24,
                                  ),
                                  tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                                  onPressed: () => manager.toggleFavorite(song.id),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Progress Bar Slider & Timestamps
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3.5,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTime(currentPos),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(totalDur),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Playback Controls Row: Shuffle, Previous (squircle), BIG Play/Pause, Next (squircle), Repeat
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Shuffle Button
                                IconButton(
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    color: manager.isShuffle ? const Color(0xFF80C8DE) : Colors.white60,
                                    size: 24,
                                  ),
                                  tooltip: 'Shuffle',
                                  onPressed: () => manager.toggleShuffle(),
                                ),

                                // Previous Track Button in Squircle
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => manager.previous(),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.skip_previous_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),

                                // BIG Circular Play / Pause Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => manager.togglePlay(),
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            blurRadius: 18,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: manager.isBuffering
                                            ? const SizedBox(
                                                width: 26,
                                                height: 26,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.8,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                ),
                                              )
                                            : Icon(
                                                manager.isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                color: Colors.black,
                                                size: 38,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Next Track Button in Squircle
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => manager.next(),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.skip_next_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),

                                // Repeat Button
                                IconButton(
                                  icon: Icon(
                                    manager.loopMode == LoopMode.one
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    color: manager.loopMode != LoopMode.off
                                        ? const Color(0xFF80C8DE)
                                        : Colors.white60,
                                    size: 24,
                                  ),
                                  tooltip: 'Repeat',
                                  onPressed: () => manager.toggleLoopMode(),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),

                          // Bottom Bar: Queue, Sleep Timer, Lyrics, More (Exact Match to Screenshot)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Queue Button with Icon & Label
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showQueueSheet(context, manager),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.queue_music_rounded,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Queue',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Sleep Timer Button
                                IconButton(
                                  icon: Icon(
                                    manager.isSleepTimerActive
                                        ? Icons.bedtime_rounded
                                        : Icons.bedtime_outlined,
                                    color: manager.isSleepTimerActive
                                        ? const Color(0xFF80C8DE)
                                        : Colors.white70,
                                    size: 20,
                                  ),
                                  tooltip: 'Sleep Timer',
                                  onPressed: () => _showSleepTimerDialog(context, manager),
                                ),

                                // Lyrics Button with Icon & Label
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showLyricsSheet(context, manager, song),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.lyrics_outlined,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Lyrics',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // More Options
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  tooltip: 'More options',
                                  onPressed: () => TrackOptionsSheet.show(context, song),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      ? const Color(0xFF0C384B).withValues(alpha: 0.85)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isCurrent
                      ? Border.all(color: const Color(0xFF80C8DE).withValues(alpha: 0.5))
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
