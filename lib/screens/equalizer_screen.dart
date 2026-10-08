import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/music_player_manager.dart';
import '../services/eq_presets.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  void _showSavePresetDialog(BuildContext context, MusicPlayerManager manager) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Save Custom EQ Preset',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g., Ultra Bass Punch, Club Sound',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF101018),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                manager.saveCustomPreset(name, manager.bandGains);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Custom preset "$name" saved!'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final isEnabled = manager.equalizerEnabled;
        final gains = manager.bandGains;

        return Scaffold(
          backgroundColor: const Color(0xFF09090F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF12121B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Studio Equalizer & DSP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: isEnabled,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    manager.toggleEqualizer(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Opacity(
            opacity: isEnabled ? 1.0 : 0.45,
            child: AbsorbPointer(
              absorbing: !isEnabled,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                children: [
                  // 1. Interactive Frequency Spline Waveform
                  Container(
                    height: 140,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [Color(0xFF18182E), Color(0xFF0F0F1A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                      ),
                    ),
                    child: CustomPaint(painter: _EqSplinePainter(gains: gains)),
                  ),

                  const SizedBox(height: 20),

                  // 2. 5-Band Vertical Frequency Sliders
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '5-BAND GRAPHIC EQUALIZER',
                                style: TextStyle(
                                  color: Color(0xFFA5B4FC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  manager.resetEqualizer();
                                },
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(5, (index) {
                            final freq = EqPresets.bandLabels[index];
                            final gain = gains[index];

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: gain != 0
                                        ? const Color(0xFF6366F1)
                                        : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 150,
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: const Color(
                                          0xFF6366F1,
                                        ),
                                        inactiveTrackColor: Colors.white12,
                                        thumbColor: Colors.white,
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                      ),
                                      child: Slider(
                                        value: gain,
                                        min: -12.0,
                                        max: 12.0,
                                        onChanged: (val) {
                                          HapticFeedback.selectionClick();
                                          manager.setBandGain(index, val);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  freq,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Audio Enhancement DSP Dials (Bass Boost, Virtualizer 3D, Loudness)
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancerCard(
                          context,
                          title: 'Bass Boost',
                          icon: Icons.speaker_rounded,
                          value: manager.bassBoost,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            manager.setBassBoost(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEnhancerCard(
                          context,
                          title: '3D Spatial',
                          icon: Icons.surround_sound_rounded,
                          value: manager.virtualizer,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            manager.setVirtualizer(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEnhancerCard(
                          context,
                          title: 'Loudness',
                          icon: Icons.volume_up_rounded,
                          value: manager.loudnessGain,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            manager.setLoudnessGain(val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Equalizer Presets & Custom Profiles
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'STUDIO SOUND PRESETS',
                              style: TextStyle(
                                color: Color(0xFFA5B4FC),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _showSavePresetDialog(context, manager),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Save Preset',
                                      style: TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...manager.soundPresets.map((preset) {
                              final isSelected = manager.soundPreset == preset;
                              return ChoiceChip(
                                label: Text(preset),
                                selected: isSelected,
                                selectedColor: const Color(0xFF6366F1),
                                backgroundColor: Colors.white.withOpacity(0.06),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  manager.setSoundPreset(preset);
                                },
                              );
                            }),
                            ...manager.customPresets.keys.map((customName) {
                              final isSelected =
                                  manager.soundPreset == customName;
                              return InputChip(
                                label: Text(customName),
                                selected: isSelected,
                                selectedColor: const Color(0xFF8B5CF6),
                                backgroundColor: Colors.white.withOpacity(0.06),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  manager.setSoundPreset(customName);
                                },
                                onDeleted: () {
                                  HapticFeedback.mediumImpact();
                                  manager.deleteCustomPreset(customName);
                                },
                                deleteIconColor: Colors.white54,
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancerCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final pct = (value * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pct%',
            style: TextStyle(
              color: pct > 0 ? const Color(0xFF6366F1) : Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EqSplinePainter extends CustomPainter {
  final List<double> gains;

  _EqSplinePainter({required this.gains});

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.isEmpty) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    final zeroY = size.height / 2;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), gridPaint);

    final points = <Offset>[];
    final stepX = size.width / (gains.length - 1);

    for (int i = 0; i < gains.length; i++) {
      final x = i * stepX;
      // Map -12..12 dB to height..0
      final normalized = (-gains[i] / 12.0).clamp(-1.0, 1.0);
      final y = zeroY + normalized * (size.height / 2 - 12);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // Gradient fill below curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6366F1).withOpacity(0.35),
          const Color(0xFF6366F1).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Glowing stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Draw control point dots
    final dotPaint = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EqSplinePainter oldDelegate) => true;
}
