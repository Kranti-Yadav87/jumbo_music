import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/music_player_manager.dart';
import 'track_details_dialog.dart';
import 'track_audio_pickers.dart';

/// Audio options list tiles: View artist, Details, Equalizer, and Tempo & Pitch.
class TrackAudioOptionsTile extends StatelessWidget {
  final Song song;
  final MusicPlayerManager manager;
  final VoidCallback? onStateUpdated;

  const TrackAudioOptionsTile({
    super.key,
    required this.song,
    required this.manager,
    this.onStateUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. View Artist Button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.person_pin_circle_outlined,
              color: Colors.white,
              size: 22,
            ),
            title: const Text(
              'View artist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Artist: ${song.artist}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // 2. Grouped Card (Details, Equalizer, Tempo and Pitch)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                title: const Text(
                  'Details',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showTrackDetailsDialog(context, song);
                },
              ),
              const Divider(height: 1, color: Color(0xFF2C2C2E)),
              ListTile(
                leading: const Icon(
                  Icons.equalizer_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                title: const Text(
                  'Equalizer',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                subtitle: Text(
                  manager.equalizerSupported
                      ? manager.soundPreset
                      : '${manager.soundPreset} • Android app only',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  showEqualizerPicker(
                    context,
                    manager,
                    onChanged: onStateUpdated,
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFF2C2C2E)),
              ListTile(
                leading: const Icon(
                  Icons.speed_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                title: const Text(
                  'Tempo and Pitch',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                subtitle: Text(
                  'x${manager.playbackSpeed.toStringAsFixed(2)} • x1.00',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  showTempoDialog(context, manager, onChanged: onStateUpdated);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
