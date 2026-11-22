import 'package:flutter/material.dart';

import '../services/music_player_manager.dart';
import 'app_cached_image.dart';
import 'equalizer_bars.dart';
import 'now_playing/now_playing_queue_sheet.dart';

/// YouTube-style "Up next" list with a quick Autoplay switch.
/// Shown beside the player on wide screens and as a sheet on phones.
class UpNextPanel extends StatelessWidget {
  final bool inSheet;

  const UpNextPanel({super.key, this.inSheet = false});

  static Future<void> show(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.78;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          SizedBox(height: height, child: const UpNextPanel(inSheet: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final queue = manager.queue;
        final current = manager.currentIndex;
        final start = (current + 1).clamp(0, queue.length);
        final upcoming = queue.sublist(start);

        return Container(
          key: const ValueKey('up-next-panel'),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            border: inSheet
                ? null
                : Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
          ),
          child: SafeArea(
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inSheet)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Up next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              manager.autoplay
                                  ? 'Autoplay keeps related songs coming'
                                  : 'Playback stops when the queue ends',
                              key: const ValueKey('up-next-autoplay-hint'),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Autoplay',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        key: const ValueKey('up-next-autoplay-switch'),
                        value: manager.autoplay,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFFFF0000),
                        onChanged: (_) => manager.toggleAutoplay(),
                      ),
                    ],
                  ),
                ),
                if (manager.isLoadingRecommendations)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: Color(0xFFFF0000),
                      backgroundColor: Colors.white10,
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: upcoming.isEmpty
                      ? _empty(manager.autoplay)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: upcoming.length,
                          itemBuilder: (context, i) {
                            final song = upcoming[i];
                            final queueIndex = start + i;
                            return InkWell(
                              key: ValueKey('up-next-item-${song.id}'),
                              onTap: () => manager.skipToQueueIndex(queueIndex),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        AppCachedImage(
                                          imageUrl: song.coverUrl,
                                          width: 112,
                                          height: 63,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          fallbackBgColor: const Color(
                                            0xFF181818,
                                          ),
                                        ),
                                        Positioned(
                                          right: 4,
                                          bottom: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            color: Colors.black87,
                                            child: Text(
                                              song.formattedDuration,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      key: ValueKey(
                                        'up-next-remove-${song.id}',
                                      ),
                                      tooltip: 'Remove from queue',
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          manager.removeFromQueue(queueIndex),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (manager.currentSong != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        EqualizerBars(
                          isPlaying: manager.isPlaying,
                          color: const Color(0xFFFF0000),
                          height: 14,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Now playing: ${manager.currentSong!.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('up-next-manage-queue-button'),
                          onPressed: () {
                            if (inSheet) Navigator.pop(context);
                            NowPlayingQueueSheet.show(context, manager);
                          },
                          child: const Text(
                            'Manage queue',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _empty(bool autoplay) {
    return Center(
      key: const ValueKey('up-next-empty'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          autoplay
              ? 'Finding related songs for you…'
              : 'Nothing queued. Turn on Autoplay to keep the music going.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
