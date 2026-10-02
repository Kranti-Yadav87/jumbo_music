/// Pure (platform independent) equalizer preset maths, so it can be unit tested.
class EqPresets {
  EqPresets._();

  static const List<String> names = [
    'Normal',
    'Bass Boost',
    'Vocal Booster',
    'Acoustic',
    'Electronic',
    'Rock',
  ];

  /// Relative gain in the range -1..1 for a frequency position `t`
  /// (0 = lowest band, 1 = highest band). Positive values scale the maximum
  /// boost of the device, negative values scale its maximum cut.
  static double curve(String preset, double t) {
    switch (preset) {
      case 'Bass Boost':
        if (t < 0.3) return 0.8;
        if (t < 0.5) return 0.3;
        return 0.0;
      case 'Vocal Booster':
        if (t < 0.2) return -0.3;
        if (t >= 0.4 && t <= 0.8) return 0.6;
        return 0.0;
      case 'Acoustic':
        if (t < 0.25) return 0.3;
        if (t > 0.75) return 0.4;
        return 0.1;
      case 'Electronic':
        if (t < 0.25 || t > 0.75) return 0.6;
        return -0.2;
      case 'Rock':
        if (t < 0.25 || t > 0.6) return 0.5;
        return -0.3;
      case 'Normal':
      default:
        return 0.0;
    }
  }

  /// Gain in decibels for every band, clamped to the device range.
  static List<double> gainsFor(
    String preset, {
    required int bandCount,
    required double minDb,
    required double maxDb,
  }) {
    return List<double>.generate(bandCount, (i) {
      final t = bandCount <= 1 ? 0.5 : i / (bandCount - 1);
      final v = curve(preset, t);
      final db = v >= 0 ? v * maxDb : v * -minDb;
      return db.clamp(minDb, maxDb).toDouble();
    });
  }
}
