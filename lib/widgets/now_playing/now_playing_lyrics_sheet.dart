import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import '../../services/lyrics_service.dart';
import '../../services/lrc_parser.dart';
import '../equalizer_bars.dart';

class NowPlayingLyricsSheet {
  NowPlayingLyricsSheet._();

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
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return _LyricsSheetContent(
              manager: manager,
              initialSong: song,
              scrollController: scrollController,
              onClose: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
  }
}

class _LyricsSheetContent extends StatefulWidget {
  final MusicPlayerManager manager;
  final Song initialSong;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const _LyricsSheetContent({
    required this.manager,
    required this.initialSong,
    required this.scrollController,
    required this.onClose,
  });

  @override
  State<_LyricsSheetContent> createState() => _LyricsSheetContentState();
}

class _LyricsSheetContentState extends State<_LyricsSheetContent> {
  late Song _currentSong;
  List<LrcLine> _lines = [];
  bool _isLoading = true;
  bool _userInteracting = false;
  int _activeIndex = -1;
  Timer? _resumeAutoScrollTimer;
  final Map<int, GlobalKey> _lineKeys = {};

  @override
  void initState() {
    super.initState();
    _currentSong = widget.initialSong;
    widget.manager.addListener(_onPlayerStateChanged);
    _loadLyricsForSong(_currentSong);
  }

  @override
  void dispose() {
    _resumeAutoScrollTimer?.cancel();
    widget.manager.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  Future<void> _loadLyricsForSong(Song song) async {
    setState(() {
      _isLoading = true;
      _lines = [];
      _lineKeys.clear();
      _activeIndex = -1;
    });

    try {
      final rawLyrics = await LyricsService.instance.fetch(song);
      if (!mounted) return;

      final totalDur = widget.manager.duration.inSeconds > 0
          ? widget.manager.duration
          : song.duration;

      final parsed = LrcParser.parse(rawLyrics ?? '', totalDuration: totalDur);

      for (int i = 0; i < parsed.length; i++) {
        _lineKeys[i] = GlobalKey();
      }

      final initialActive = LrcParser.findActiveIndex(
        parsed,
        widget.manager.position,
      );

      setState(() {
        _isLoading = false;
        _lines = parsed;
        _activeIndex = initialActive;
      });

      // Initial auto-scroll to current position
      if (initialActive >= 0 && parsed.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(initialActive, animated: false);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lines = [];
        });
      }
    }
  }

  void _onPlayerStateChanged() {
    final activeSong = widget.manager.currentSong;
    if (activeSong != null && activeSong.id != _currentSong.id) {
      _currentSong = activeSong;
      _loadLyricsForSong(activeSong);
      return;
    }

    if (_lines.isEmpty) return;

    final newIndex = LrcParser.findActiveIndex(_lines, widget.manager.position);

    if (newIndex != _activeIndex) {
      setState(() {
        _activeIndex = newIndex;
      });

      if (!_userInteracting) {
        _scrollToIndex(newIndex, animated: true);
      }
    }
  }

  void _scrollToIndex(int index, {bool animated = true}) {
    if (!mounted || index < 0 || index >= _lines.length) return;

    final key = _lineKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment:
            0.18, // Auto-scroll active line to top 18% so upcoming lines below are fully visible
        duration: animated ? const Duration(milliseconds: 380) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    } else if (widget.scrollController.hasClients) {
      final target = (index * 62.0 - 30.0).clamp(
        0.0,
        widget.scrollController.position.maxScrollExtent,
      );
      if (animated) {
        widget.scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      } else {
        widget.scrollController.jumpTo(target);
      }
    }
  }

  void _resumeAutoScrollNow() {
    _resumeAutoScrollTimer?.cancel();
    setState(() {
      _userInteracting = false;
    });
    _scrollToIndex(_activeIndex, animated: true);
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
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lyrics_rounded,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSong.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentSong.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: Stack(
            children: [
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF38BDF8),
                    ),
                  ),
                )
              else if (_lines.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No lyrics found for this song',
                        style: TextStyle(color: Colors.white60, fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => _loadLyricsForSong(_currentSong),
                      ),
                    ],
                  ),
                )
              else
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification &&
                        notification.dragDetails != null) {
                      if (!_userInteracting) {
                        setState(() => _userInteracting = true);
                      }
                      _resumeAutoScrollTimer?.cancel();
                    } else if (notification is ScrollEndNotification) {
                      _resumeAutoScrollTimer?.cancel();
                      _resumeAutoScrollTimer = Timer(
                        const Duration(seconds: 4),
                        () {
                          if (mounted && _userInteracting) {
                            setState(() => _userInteracting = false);
                            _scrollToIndex(_activeIndex, animated: true);
                          }
                        },
                      );
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: widget.scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      MediaQuery.of(context).size.height * 0.55,
                    ),
                    itemCount: _lines.length,
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      final isCurrent = index == _activeIndex;
                      final isPast = index < _activeIndex;

                      final timeStr =
                          '${line.timestamp.inMinutes}:${(line.timestamp.inSeconds % 60).toString().padLeft(2, '0')}';

                      return InkWell(
                        key: _lineKeys[index],
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          widget.manager.seek(line.timestamp);
                          _resumeAutoScrollNow();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF1E2D4A).withOpacity(0.9)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isCurrent
                                ? Border.all(
                                    color: const Color(
                                      0xFF38BDF8,
                                    ).withOpacity(0.6),
                                    width: 1.2,
                                  )
                                : null,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF38BDF8,
                                      ).withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (isCurrent) ...[
                                EqualizerBars(
                                  isPlaying: widget.manager.isPlaying,
                                  color: const Color(0xFF38BDF8),
                                  height: 16,
                                ),
                                const SizedBox(width: 12),
                              ] else ...[
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: isPast
                                          ? Colors.white24
                                          : Colors.white38,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  line.text,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? const Color(0xFF38BDF8)
                                        : isPast
                                        ? Colors
                                              .white38 // Passed lines are softly dimmed
                                        : Colors.white.withOpacity(
                                            0.92,
                                          ), // Upcoming (niche wali) lines are crisp & bright
                                    fontSize: isCurrent ? 18 : 15,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Floating Auto-scroll sync pill when user scrolled away
              if (_userInteracting && _lines.isNotEmpty && _activeIndex >= 0)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _resumeAutoScrollNow,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Auto-scroll to current line',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
