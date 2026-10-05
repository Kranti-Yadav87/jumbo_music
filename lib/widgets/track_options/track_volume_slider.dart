import 'package:flutter/material.dart';
import '../../services/music_player_manager.dart';

/// Volume control card in TrackOptionsSheet.
class TrackVolumeSlider extends StatelessWidget {
  final MusicPlayerManager manager;

  const TrackVolumeSlider({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final volumePercent = (manager.volume * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Volume',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$volumePercent%',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape: SliderComponentShape.noThumb,
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: const Color(0xFFE5A5A5),
                    inactiveTrackColor: const Color(0xFF2C2C2E),
                  ),
                  child: Slider(
                    value: manager.volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) => manager.setVolume(val),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF8E8E93),
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
