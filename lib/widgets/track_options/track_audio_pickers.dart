import 'package:flutter/material.dart';
import '../../services/music_player_manager.dart';

/// Modal bottom sheet for choosing Equalizer sound preset.
void showEqualizerPicker(
  BuildContext context,
  MusicPlayerManager manager, {
  VoidCallback? onChanged,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141416),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
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
              const SizedBox(height: 14),
              const Text(
                'Equalizer Presets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                    selectedColor: const Color(0xFFE5A5A5),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.black : Colors.white70,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      manager.setSoundPreset(preset);
                      Navigator.pop(ctx);
                      onChanged?.call();
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

/// Modal bottom sheet for setting playback speed (Tempo & Pitch).
void showTempoDialog(
  BuildContext context,
  MusicPlayerManager manager, {
  VoidCallback? onChanged,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141416),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tempo and Pitch',
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
                    label: Text('x${speed.toStringAsFixed(2)}'),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE5A5A5),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      manager.setPlaybackSpeed(speed);
                      Navigator.pop(ctx);
                      onChanged?.call();
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
