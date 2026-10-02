import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import '../services/lrc_parser.dart';
import 'app_cached_image.dart';
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
    Clipboard.setData(
      ClipboardData(
        text: '${song.title} by ${song.artist} - Listen on Jumbo Music',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied "${song.title} - ${song.artist}" to clipboard! Ready to share.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLyricsSheet(
    BuildContext context,
    MusicPlayerManager manager,
    Song song,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
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
                          const Icon(
                            Icons.lyrics_rounded,
                            color: Color(0xFF38BDF8),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Lyrics • ${song.title}',
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
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white60,
                            ),
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
                          _buildSyncedLyricsSliver(
                            context,
                            manager,
                            song,
                            currentPos,
                            totalDur,
                          ),
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
      backgroundColor: const Color(0xFF090F1C),
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

                    // Queue Header Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.queue_music_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Up Next Queue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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

                    if (song != null)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131F38),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withOpacity(0.4),
                            ),
                          ),
                          child: ListTile(
                            leading: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppCachedImage(
                                    imageUrl: song.coverUrl,
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
                                    color: const Color(0xFF38BDF8),
                                    height: 14,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Now Playing • ${song.artist}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav
                                    ? const Color(0xFFFF5E7E)
                                    : Colors.white70,
                                size: 22,
                              ),
                              onPressed: () => manager.toggleFavorite(song.id),
                            ),
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(
                      child: Divider(color: Colors.white12, height: 20),
                    ),

                    // Queue List
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = queue[index];
                        final isCurrent = song != null && item.id == song.id;
                        if (isCurrent) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppCachedImage(
                                imageUrl: item.coverUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
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
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white54,
                              ),
                              onPressed: () =>
                                  TrackOptionsSheet.show(context, item),
                            ),
                            onTap: () => manager.playSong(item),
                          ),
                        );
                      }, childCount: queue.length),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
    final downloadService = DownloadService();

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        final song = manager.currentSong;

        if (song == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF081220),
            body: Center(
              child: Text(
                'No song playing',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        final isFav = manager.isFavorite(song.id);
        final isDl = downloadService.isDownloaded(song.id);
        final isDling = downloadService.isDownloading(song.id);
        final currentPos = manager.position;
        final totalDur = manager.duration.inSeconds > 0
            ? manager.duration
            : song.duration;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            // Swiping UP opens the Queue sheet
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -180) {
              _showQueueSheet(context, manager);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF081220),
            body: Stack(
              children: [
                // 1. Ambient Background Gradient (Deep Navy Blue matching Screenshot 2)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(
                            0xFF0B192E,
                          ), // Deep midnight blue tint from Screenshot 2
                          Color(0xFF081220),
                          Color(0xFF040810),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Soft central glow behind artwork
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withOpacity(0.12),
                            blurRadius: 120,
                            spreadRadius: 30,
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
                      final maxAllowedWidth = (screenWidth - 48).clamp(
                        200.0,
                        340.0,
                      );
                      final coverSize = (screenHeight * 0.38).clamp(
                        200.0,
                        maxAllowedWidth,
                      );

                      return Column(
                        children: [
                          // 1. TOP BAR: Down Arrow (v) + "PLAYING FROM SELECTION" / "Random Selection" + 3-dots (:) - Screenshot 2
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Down Arrow (v)
                                IconButton(
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),

                                // Center Source Text (PLAYING FROM SELECTION / "Random Selection")
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'PLAYING FROM SELECTION',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        song.album.isNotEmpty
                                            ? '"${song.album}"'
                                            : '"Random Selection"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 3-dots Menu (:)
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      TrackOptionsSheet.show(context, song),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),

                          // 2. LARGE SQUARE ALBUM ARTWORK - Screenshot 2 (Coldplay Wings style)
                          Center(
                            child: Container(
                              width: coverSize,
                              height: coverSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFF38BDF8,
                                    ).withOpacity(0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: AppCachedImage(
                                imageUrl: song.coverUrl,
                                borderRadius: BorderRadius.circular(20),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 3. QUICK ACTION PILLS ROW: [SHARE] [DOWNLOAD] [LYRICS] - EXACT MATCH TO SCREENSHOT 2
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Share Pill Button
                                _buildActionPill(
                                  icon: Icons.reply_rounded,
                                  label: 'SHARE',
                                  onTap: () => _shareSong(context, song),
                                ),
                                const SizedBox(width: 10),

                                // Download Pill Button (Saves offline in app)
                                _buildActionPill(
                                  icon: isDl
                                      ? Icons.check_circle_rounded
                                      : (isDling
                                            ? Icons.hourglass_top_rounded
                                            : Icons.download_rounded),
                                  label: isDl
                                      ? 'DOWNLOADED'
                                      : (isDling ? 'SAVING...' : 'DOWNLOAD'),
                                  iconColor: isDl
                                      ? const Color(0xFF10B981)
                                      : Colors.white,
                                  onTap: () => downloadService.downloadSong(
                                    song,
                                    context: context,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Lyrics Pill Button
                                _buildActionPill(
                                  icon: Icons.article_outlined,
                                  label: 'LYRICS',
                                  onTap: () =>
                                      _showLyricsSheet(context, manager, song),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),

                          // 4. SONG TITLE, ARTIST, AND FAVORITE HEART BUTTON - Screenshot 2
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Like Heart Button (🤍 / ❤️)
                                IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? const Color(0xFFFF5E7E)
                                        : Colors.white,
                                    size: 26,
                                  ),
                                  tooltip: isFav
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                                  onPressed: () =>
                                      manager.toggleFavorite(song.id),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 5. PROGRESS SLIDER & TIMESTAMPS (0:26 / 4:28) - Screenshot 2
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3.5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white
                                        .withOpacity(0.2),
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    min: 0.0,
                                    max: max(
                                      1.0,
                                      totalDur.inMilliseconds.toDouble(),
                                    ),
                                    value:
                                        (_dragValue ??
                                                currentPos.inMilliseconds
                                                    .toDouble())
                                            .clamp(
                                              0.0,
                                              max(
                                                1.0,
                                                totalDur.inMilliseconds
                                                    .toDouble(),
                                              ),
                                            ),
                                    onChanged: (val) {
                                      setState(() {
                                        _dragValue = val;
                                      });
                                    },
                                    onChangeEnd: (val) {
                                      manager.seek(
                                        Duration(milliseconds: val.toInt()),
                                      );
                                      setState(() {
                                        _dragValue = null;
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTime(currentPos),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(totalDur),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.65),
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

                          // 6. PLAYBACK CONTROLS: Shuffle, Previous, Big Play/Pause, Next, Loop - Screenshot 2
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Shuffle Button
                                IconButton(
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    color: manager.isShuffle
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white60,
                                    size: 24,
                                  ),
                                  tooltip: 'Shuffle',
                                  onPressed: () => manager.toggleShuffle(),
                                ),

                                // Previous Track Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  tooltip: 'Previous',
                                  onPressed: () => manager.previous(),
                                ),

                                // BIG Circular Play / Pause Button - Screenshot 2
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      manager.togglePlay();
                                    },
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF132038),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          transitionBuilder: (child, anim) =>
                                              ScaleTransition(
                                                scale: anim,
                                                child: child,
                                              ),
                                          child:
                                              (manager.isBuffering &&
                                                  !manager.isPlaying)
                                              ? const SizedBox(
                                                  key: ValueKey('buffering'),
                                                  width: 26,
                                                  height: 26,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.8,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Icon(
                                                  manager.isPlaying
                                                      ? Icons.pause_rounded
                                                      : Icons
                                                            .play_arrow_rounded,
                                                  key: ValueKey(
                                                    manager.isPlaying
                                                        ? 'pause'
                                                        : 'play',
                                                  ),
                                                  color: Colors.white,
                                                  size: 38,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Next Track Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_next_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  tooltip: 'Next',
                                  onPressed: () => manager.next(),
                                ),

                                // Loop / Autoplay Button
                                IconButton(
                                  icon: Icon(
                                    manager.autoplay
                                        ? Icons.all_inclusive_rounded
                                        : (manager.loopMode == LoopMode.one
                                              ? Icons.repeat_one_rounded
                                              : Icons.repeat_rounded),
                                    color:
                                        manager.autoplay ||
                                            manager.loopMode != LoopMode.off
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white60,
                                    size: 24,
                                  ),
                                  tooltip: 'Autoplay / Repeat',
                                  onPressed: () => manager.toggleAutoplay(),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),

                          // 7. BOTTOM UP ARROW (^) - TRIGGER FOR UP NEXT QUEUE (Screenshot 2)
                          GestureDetector(
                            onTap: () => _showQueueSheet(context, manager),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  Text(
                                    'Swipe up for Queue',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),
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

  // Quick Action Pill Builder matching Screenshot 2 ([SHARE] [DOWNLOAD] [LYRICS])
  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncedLyricsSliver(
    BuildContext context,
    MusicPlayerManager manager,
    Song song,
    Duration currentPos,
    Duration totalDur,
  ) {
    final lrcLines = LrcParser.parse(song.lyrics, totalDuration: totalDur);
    final activeIndex = LrcParser.findActiveIndex(lrcLines, currentPos);

    if (lrcLines.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No lyrics available for this track',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final line = lrcLines[index];
          final isCurrent = index == activeIndex;
          final isPast = index < activeIndex;

          final timeStr =
              '${line.timestamp.inMinutes}:${(line.timestamp.inSeconds % 60).toString().padLeft(2, '0')}';

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              manager.seek(line.timestamp);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF1E2D4A).withOpacity(0.85)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isCurrent
                    ? Border.all(
                        color: const Color(0xFF38BDF8).withOpacity(0.5),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  if (isCurrent) ...[
                    EqualizerBars(
                      isPlaying: manager.isPlaying,
                      color: const Color(0xFF38BDF8),
                      height: 14,
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: isPast ? Colors.white30 : Colors.white24,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      line.text,
                      style: TextStyle(
                        color: isCurrent
                            ? const Color(0xFF38BDF8)
                            : isPast
                            ? Colors.white70
                            : Colors.white30,
                        fontSize: isCurrent ? 17 : 15,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: lrcLines.length),
      ),
    );
  }
}
