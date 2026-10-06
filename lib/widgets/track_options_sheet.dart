import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';
import 'track_options/track_options_header.dart';
import 'track_options/track_volume_slider.dart';
import 'track_options/track_actions_row.dart';
import 'track_options/track_download_tile.dart';
import 'track_options/track_audio_options_tile.dart';

class TrackOptionsSheet extends StatefulWidget {
  final Song song;

  const TrackOptionsSheet({super.key, required this.song});

  static Future<void> show(BuildContext context, Song song) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(song: song),
    );
  }

  @override
  State<TrackOptionsSheet> createState() => _TrackOptionsSheetState();
}

class _TrackOptionsSheetState extends State<TrackOptionsSheet> {
  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final downloadService = DownloadService();
    final song = widget.song;

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Drag Handle & Now Playing Track Header
                  TrackOptionsHeader(song: song),

                  const SizedBox(height: 12),

                  // 2. Volume Card & Slider
                  TrackVolumeSlider(manager: manager),

                  const SizedBox(height: 12),

                  // 3. Action Grid (Radio, Playlist, Copy link) & Flame badge
                  TrackActionsRow(song: song, manager: manager),

                  const SizedBox(height: 12),

                  // 4. Prominent 320kbps Download Status Tile
                  TrackDownloadTile(
                    song: song,
                    downloadService: downloadService,
                  ),

                  const SizedBox(height: 10),

                  // 5. Audio Options: View Artist, Details, Equalizer, Tempo & Pitch
                  TrackAudioOptionsTile(
                    song: song,
                    manager: manager,
                    onStateUpdated: () => setState(() {}),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
