/// Pure (platform independent) equalizer preset maths & 5-band frequency definitions.
class EqPresets {
  EqPresets._();

  static const List<int> bandFrequencies = [60, 230, 910, 3600, 14000];

  static const List<String> bandLabels = [
    '60Hz',
    '230Hz',
    '910Hz',
    '3.6kHz',
    '14kHz',
  ];

  static const Map<String, List<double>> factoryPresetGains = {
    'Normal': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass Boost': [6.0, 4.5, 1.0, 0.0, 0.0],
    'Pop': [-1.5, 2.0, 4.5, 3.0, -1.0],
    'Rock': [5.0, 3.0, -1.5, 3.5, 5.5],
    'Electronic': [5.5, 4.0, -1.0, 2.5, 4.5],
    'Jazz': [3.0, 2.0, -1.5, 2.5, 3.5],
    'Acoustic': [3.5, 2.0, 1.0, 3.0, 4.0],
    'Classical': [4.0, 2.5, -1.0, 2.5, 3.5],
    'Hip Hop': [6.5, 5.0, 0.5, 2.0, 3.5],
    'Vocal Booster': [-2.5, 0.0, 4.5, 4.0, 1.0],
    'Treble Boost': [-2.0, -1.0, 1.0, 4.5, 7.0],
    'Deep Sub': [8.0, 5.5, 1.0, -1.0, -2.0],
  };

  static List<String> get names => factoryPresetGains.keys.toList();

  /// Returns standard 5-band gains for a preset
  static List<double> getGainsForPreset(String preset) {
    if (factoryPresetGains.containsKey(preset)) {
      return List<double>.from(factoryPresetGains[preset]!);
    }
    return [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  /// Relative gain in the range -1..1 for frequency position `t` (0 = low, 1 = high)
  static double curve(String preset, double t) {
    final gains = getGainsForPreset(preset);
    if (gains.isEmpty) return 0.0;
    final index =
        (t * (gains.length - 1)).clamp(0.0, (gains.length - 1).toDouble());
    final low = index.floor();
    final high = index.ceil();
    if (low == high) return (gains[low] / 12.0).clamp(-1.0, 1.0);
    final frac = index - low;
    final val = gains[low] * (1.0 - frac) + gains[high] * frac;
    return (val / 12.0).clamp(-1.0, 1.0);
  }

  /// Gain in decibels for any requested band count
  static List<double> gainsFor(
    String preset, {
    required int bandCount,
    required double minDb,
    required double maxDb,
  }) {
    if (bandCount == 5 && factoryPresetGains.containsKey(preset)) {
      final base = factoryPresetGains[preset]!;
      return base.map((g) => g.clamp(minDb, maxDb)).toList();
    }
    return List<double>.generate(bandCount, (i) {
      final t = bandCount <= 1 ? 0.5 : i / (bandCount - 1);
      final v = curve(preset, t);
      final db = v >= 0 ? v * maxDb : v * -minDb;
      return db.clamp(minDb, maxDb).toDouble();
    });
  }
}
