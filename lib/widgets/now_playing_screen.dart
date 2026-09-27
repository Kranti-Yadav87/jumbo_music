import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import 'equalizer_bars.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _vinylController;
  bool _showLyrics = false;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    final manager = MusicPlayerManager();
    if (manager.isPlaying) {
      _vinylController.repeat();
    }
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSleepTimerPicker(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.bedtime_rounded, color: Color(0xFF818CF8)),
                    const SizedBox(width: 8),
                    const Text(
                      'Bedtime Sleep Timer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (manager.isSleepTimerActive)
                      TextButton(
                        onPressed: () {
                          manager.cancelSleepTimer();
                          Navigator.pop(context);
                        },
                        child: const Text('Turn Off', style: TextStyle(color: Colors.redAccent)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSleepOption(context, manager, '15 Minutes', const Duration(minutes: 15)),
                _buildSleepOption(context, manager, '30 Minutes', const Duration(minutes: 30)),
                _buildSleepOption(context, manager, '45 Minutes', const Duration(minutes: 45)),
                _buildSleepOption(context, manager, '60 Minutes', const Duration(minutes: 60)),
                ListTile(
                  leading: const Icon(Icons.music_off_rounded, color: Color(0xFF818CF8)),
                  title: const Text('End of Current Song', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    manager.setSleepTimerAfterSong();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepOption(BuildContext context, MusicPlayerManager manager, String title, Duration dur) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined, color: Colors.white54),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        manager.setSleepTimer(dur);
        Navigator.pop(context);
      },
    );
  }

  void _showPresetPicker(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.graphic_eq_rounded, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Text(
                      'Audio Equalizer Presets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: manager.soundPresets.map((preset) {
                    final isSel = manager.soundPreset == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSel,
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        manager.setSoundPreset(preset);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrackInfo(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Title', song.title),
                _buildInfoRow('Artist', song.artist),
                _buildInfoRow('Album', song.album),
                _buildInfoRow('Genre', song.genre),
                _buildInfoRow('Year', song.releaseYear),
                _buildInfoRow('Audio Quality', song.quality),
                _buildInfoRow('Duration', song.formattedDuration),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showQueueSheet(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.queue_music, color: Color(0xFF818CF8)),
                    const SizedBox(width: 8),
                    const Text(
                      'Playback Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${manager.queue.length} songs',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  itemCount: manager.queue.length,
                  itemBuilder: (context, index) {
                    final song = manager.queue[index];
                    final isCurrent = manager.currentIndex == index;

                    return Dismissible(
                      key: Key('queue_${song.id}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.withOpacity(0.8),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        manager.removeFromQueue(index);
                      },
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            song.coverUrl,
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 45,
                              height: 45,
                              color: Colors.white10,
                              child: const Icon(Icons.music_note, color: Colors.white54),
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? const Color(0xFF818CF8) : Colors.white,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.volume_up, color: Color(0xFF818CF8))
                            : IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                                onPressed: () => manager.removeFromQueue(index),
                              ),
                        onTap: () {
                          manager.playSong(song);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedPicker(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: speeds.map((speed) {
                    final isSelected = (manager.playbackSpeed == speed);
                    return ChoiceChip(
                      label: Text('${speed}x'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        manager.setPlaybackSpeed(speed);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
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

        if (manager.isPlaying) {
          if (!_vinylController.isAnimating) {
            _vinylController.repeat();
          }
        } else {
          _vinylController.stop();
        }

        if (song == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0C0C14),
            body: Center(
              child: Text(
                'No song selected',
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

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF0F0E26),
                  Color(0xFF09090F),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Top App Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                          color: Colors.white,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'NOW PLAYING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF818CF8),
                                  ),
                                ),
                                if (manager.isSleepTimerActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF818CF8).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.bedtime_rounded,
                                          size: 10,
                                          color: Color(0xFF818CF8),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          manager.formattedSleepTime,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF818CF8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.album,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline_rounded, size: 22),
                              color: Colors.white70,
                              onPressed: () => _showTrackInfo(context, song),
                            ),
                            IconButton(
                              icon: const Icon(Icons.queue_music, size: 24),
                              color: Colors.white70,
                              onPressed: () => _showQueueSheet(context, manager),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Artwork or Lyrics View
                    Expanded(
                      flex: 8,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showLyrics
                            ? _buildLyricsView(song)
                            : _buildArtworkView(song, manager),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Title & Artist & Favorite
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${song.artist} • ${song.releaseYear}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? const Color(0xFFEF4444) : Colors.white60,
                            size: 28,
                          ),
                          onPressed: () => manager.toggleFavorite(song.id),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Progress Slider & Timers
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: const Color(0xFF818CF8),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                            overlayColor: const Color(0xFF818CF8).withOpacity(0.2),
                          ),
                          child: Slider(
                            min: 0.0,
                            max: max(1.0, totalDur.inMilliseconds.toDouble()),
                            value: (_dragValue ??
                                    currentPos.inMilliseconds.toDouble())
                                .clamp(
                                    0.0,
                                    max(1.0,
                                        totalDur.inMilliseconds.toDouble())),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                _formatTime(totalDur),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Primary Playback Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shuffle
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: manager.isShuffle
                                ? const Color(0xFF818CF8)
                                : Colors.white38,
                            size: 24,
                          ),
                          onPressed: () => manager.toggleShuffle(),
                        ),

                        // Previous
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                          onPressed: () => manager.previous(),
                        ),

                        // Play / Pause Hero
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.45),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(34),
                              onTap: () => manager.togglePlay(),
                              child: Center(
                                child: manager.isBuffering
                                    ? const SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        manager.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // Next
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                          onPressed: () => manager.next(),
                        ),

                        // Loop Mode
                        IconButton(
                          icon: Icon(
                            manager.loopMode == LoopMode.one
                                ? Icons.repeat_one_rounded
                                : manager.loopMode == LoopMode.all
                                    ? Icons.repeat_on_rounded
                                    : Icons.repeat_rounded,
                            color: manager.loopMode != LoopMode.off
                                ? const Color(0xFF818CF8)
                                : Colors.white38,
                            size: 24,
                          ),
                          onPressed: () => manager.toggleLoopMode(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Volume Bar Row
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            manager.isMuted || manager.volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_down_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => manager.toggleMute(),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 4,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
                              ),
                              activeTrackColor: Colors.white70,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: manager.volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) => manager.setVolume(val),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Bottom Quick Tools: Lyrics, Speed, Preset, Sleep
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickButton(
                            icon: Icons.lyrics_outlined,
                            label: _showLyrics ? 'Art' : 'Lyrics',
                            isActive: _showLyrics,
                            onTap: () {
                              setState(() {
                                _showLyrics = !_showLyrics;
                              });
                            },
                          ),
                          _buildQuickButton(
                            icon: Icons.speed_rounded,
                            label: '${manager.playbackSpeed}x',
                            isActive: manager.playbackSpeed != 1.0,
                            onTap: () => _showSpeedPicker(context, manager),
                          ),
                          _buildQuickButton(
                            icon: Icons.graphic_eq_rounded,
                            label: manager.soundPreset,
                            isActive: manager.soundPreset != 'Normal',
                            onTap: () => _showPresetPicker(context, manager),
                          ),
                          _buildQuickButton(
                            icon: Icons.bedtime_rounded,
                            label: manager.isSleepTimerActive ? manager.formattedSleepTime : 'Sleep',
                            isActive: manager.isSleepTimerActive,
                            onTap: () => _showSleepTimerPicker(context, manager),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withOpacity(0.25)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF818CF8) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF818CF8) : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? const Color(0xFF818CF8) : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkView(Song song, MusicPlayerManager manager) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  song.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF262638),
                    child: const Icon(
                      Icons.music_note,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
                ),
                if (manager.isPlaying)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EqualizerBars(
                            isPlaying: true,
                            color: const Color(0xFF818CF8),
                            height: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            song.quality,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLyricsView(Song song) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lyrics, color: Color(0xFF818CF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Lyrics & Song Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                song.lyrics.isNotEmpty
                    ? song.lyrics
                    : 'Lyrics are not available for this song yet.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
