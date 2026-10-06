import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import '../../services/lyrics_service.dart';
import '../../services/lrc_parser.dart';
import '../equalizer_bars.dart';

class NowPlayingLyricsSheet extends StatefulWidget {
  final MusicPlayerManager manager;
  final Song song;
  final ScrollController? scrollController;

  const NowPlayingLyricsSheet({
    super.key,
    required this.manager,
    required this.song,
    this.scrollController,
  });

  static void show(
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
            return NowPlayingLyricsSheet(
              manager: manager,
              song: song,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  State<NowPlayingLyricsSheet> createState() => _NowPlayingLyricsSheetState();
}

class _NowPlayingLyricsSheetState extends State<NowPlayingLyricsSheet> {
  late final ValueNotifier<int> _activeIndexNotifier;
  late final ValueNotifier<bool> _isPlayingNotifier;
  late final Future<List<LrcLine>> _lyricsFuture;
  List<LrcLine> _lrcLines = const [];

  @override
  void initState() {
    super.initState();
    _activeIndexNotifier = ValueNotifier<int>(-1);
    _isPlayingNotifier = ValueNotifier<bool>(widget.manager.isPlaying);

    widget.manager.addListener(_onManagerChanged);
    widget.manager.positionListenable.addListener(_onPositionChanged);

    final totalDur = widget.manager.duration.inSeconds > 0
        ? widget.manager.duration
        : widget.song.duration;

    _lyricsFuture = LyricsService.instance.fetch(widget.song).then((raw) {
      final parsed = LrcParser.parse(raw ?? '', totalDuration: totalDur);
      _lrcLines = parsed;
      _updateActiveIndex(widget.manager.positionListenable.value);
      return parsed;
    });
  }

  void _onManagerChanged() {
    if (_isPlayingNotifier.value != widget.manager.isPlaying) {
      _isPlayingNotifier.value = widget.manager.isPlaying;
    }
  }

  void _onPositionChanged() {
    _updateActiveIndex(widget.manager.positionListenable.value);
  }

  void _updateActiveIndex(Duration currentPos) {
    if (_lrcLines.isEmpty) {
      if (_activeIndexNotifier.value != -1) {
        _activeIndexNotifier.value = -1;
      }
      return;
    }
    final newIndex = LrcParser.findActiveIndex(_lrcLines, currentPos);
    if (_activeIndexNotifier.value != newIndex) {
      _activeIndexNotifier.value = newIndex;
    }
  }

  @override
  void dispose() {
    widget.manager.removeListener(_onManagerChanged);
    widget.manager.positionListenable.removeListener(_onPositionChanged);
    _isPlayingNotifier.dispose();
    _activeIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Lyrics • ${widget.song.title}',
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
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: FutureBuilder<List<LrcLine>>(
            future: _lyricsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF38BDF8),
                    ),
                  ),
                );
              }
              final lrcLines = snapshot.data ?? const [];
              if (lrcLines.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No lyrics available for this track',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                );
              }

              return ValueListenableBuilder<int>(
                valueListenable: _activeIndexNotifier,
                builder: (context, activeIndex, _) {
                  return CustomScrollView(
                    controller: widget.scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final line = lrcLines[index];
                            final isCurrent = index == activeIndex;
                            final isPast = index < activeIndex;

                            final timeStr =
                                '${line.timestamp.inMinutes}:${(line.timestamp.inSeconds % 60).toString().padLeft(2, '0')}';

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                widget.manager.seek(line.timestamp);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(
                                          0xFF1E2D4A,
                                        ).withOpacity(0.85)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isCurrent
                                      ? Border.all(
                                          color: const Color(
                                            0xFF38BDF8,
                                          ).withOpacity(0.5),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    if (isCurrent) ...[
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isPlayingNotifier,
                                        builder: (context, isPlaying, _) {
                                          return EqualizerBars(
                                            isPlaying: isPlaying,
                                            color: const Color(0xFF38BDF8),
                                            height: 14,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                    ] else ...[
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: isPast
                                              ? Colors.white30
                                              : Colors.white24,
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
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
