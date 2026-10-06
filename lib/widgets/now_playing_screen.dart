import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import '../services/share_service.dart';
import 'app_cached_image.dart';
import 'track_options_sheet.dart';
import 'now_playing/now_playing_action_pill.dart';
import 'now_playing/now_playing_lyrics_sheet.dart';
import 'now_playing/now_playing_queue_sheet.dart';

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

  void _shareSong(BuildContext context, Song song) {
    ShareService.shareSong(context, song);
  }

  void _showLyricsSheet(
    BuildContext context,
    MusicPlayerManager manager,
    Song song,
  ) {
    NowPlayingLyricsSheet.show(context, manager, song);
  }

  void _showQueueSheet(BuildContext context, MusicPlayerManager manager) {
    NowPlayingQueueSheet.show(context, manager);
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
                                NowPlayingActionPill(
                                  icon: Icons.reply_rounded,
                                  label: 'SHARE',
                                  onTap: () => _shareSong(context, song),
                                ),
                                const SizedBox(width: 10),

                                // Download Pill Button (Saves offline in app)
                                NowPlayingActionPill(
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
                                NowPlayingActionPill(
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
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(
                                            0xFF94A3B8,
                                          ), // Subdued Slate Grey from Screenshot 2
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Glowing Favorite Button
                                IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? const Color(0xFFFF5E7E)
                                        : Colors.white60,
                                    size: 28,
                                  ),
                                  tooltip: isFav
                                      ? 'Remove from Favorites'
                                      : 'Add to Favorites',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    manager.toggleFavorite(song.id);
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 5. SEEK SLIDER BAR + REAL-TIME DURATION (Screenshot 2: Glowing cyan progress line)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ValueListenableBuilder<Duration>(
                              valueListenable: manager.positionNotifier,
                              builder: (context, currentPos, _) {
                                return ValueListenableBuilder<Duration>(
                                  valueListenable: manager.durationNotifier,
                                  builder: (context, durationVal, _) {
                                    final totalDur = durationVal.inSeconds > 0
                                        ? durationVal
                                        : song.duration;
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 3.5,
                                            activeTrackColor: const Color(
                                              0xFF38BDF8,
                                            ), // Glowing Light Sky Blue from Screenshot 2
                                            inactiveTrackColor: Colors.white
                                                .withOpacity(0.15),
                                            thumbColor: Colors.white,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6.0,
                                                ),
                                            overlayColor: const Color(
                                              0xFF38BDF8,
                                            ).withOpacity(0.2),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                                  overlayRadius: 14.0,
                                                ),
                                          ),
                                          child: Slider(
                                            value:
                                                (_dragValue ??
                                                        currentPos
                                                            .inMilliseconds
                                                            .toDouble())
                                                    .clamp(
                                                      0.0,
                                                      max(
                                                        1.0,
                                                        totalDur.inMilliseconds
                                                            .toDouble(),
                                                      ),
                                                    ),
                                            min: 0.0,
                                            max: max(
                                              1.0,
                                              totalDur.inMilliseconds
                                                  .toDouble(),
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                _dragValue = val;
                                              });
                                            },
                                            onChangeEnd: (val) {
                                              manager.seek(
                                                Duration(
                                                  milliseconds: val.toInt(),
                                                ),
                                              );
                                              setState(() {
                                                _dragValue = null;
                                              });
                                            },
                                          ),
                                        ),

                                        // Time Stamps: 0:00 (left) vs -3:24 (right) matching Screenshot 2
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatTime(
                                                  _dragValue != null
                                                      ? Duration(
                                                          milliseconds:
                                                              _dragValue!
                                                                  .toInt(),
                                                        )
                                                      : currentPos,
                                                ),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.55),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                totalDur > currentPos
                                                    ? '-${_formatTime(totalDur - (_dragValue != null ? Duration(milliseconds: _dragValue!.toInt()) : currentPos))}'
                                                    : _formatTime(totalDur),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.55),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 6. BOTTOM CONTROLS ROW: Shuffle | Prev | Play/Pause Big Button | Next | Repeat
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
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

                                // CENTER BIG PLAY / PAUSE BUTTON (Navy blue circle with thin white border) - Screenshot 2
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
}
