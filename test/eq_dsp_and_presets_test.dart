import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/eq_presets.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Equalizer DSP, Custom Sliders & Math Interpolation Tests', () {
    late DatabaseService db;
    late MusicPlayerManager manager;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();
      manager = MusicPlayerManager();
      manager.resetEqualizer();
    });

    test('EqPresets.interpolateGains maps 5 bands to 5 bands accurately', () {
      final input = [2.0, 4.0, -1.0, 3.0, 5.0];
      final result = EqPresets.interpolateGains(
        input,
        targetBandCount: 5,
        minDb: -12.0,
        maxDb: 12.0,
      );

      expect(result.length, equals(5));
      expect(result[0], equals(2.0));
      expect(result[1], equals(4.0));
      expect(result[2], equals(-1.0));
      expect(result[3], equals(3.0));
      expect(result[4], equals(5.0));
    });

    test('EqPresets.interpolateGains maps 5 bands to N hardware bands', () {
      final input = [6.0, 3.0, 0.0, 3.0, 6.0];
      final result10Bands = EqPresets.interpolateGains(
        input,
        targetBandCount: 10,
        minDb: -12.0,
        maxDb: 12.0,
      );

      expect(result10Bands.length, equals(10));
      // First band should be low, last band should be high
      expect(result10Bands.first, equals(6.0));
      expect(result10Bands.last, equals(6.0));
      // Mid bands should be smooth
      for (final gain in result10Bands) {
        expect(gain >= -12.0 && gain <= 12.0, isTrue);
      }
    });

    test(
      'EqPresets.interpolateGains applies Bass Boost to low frequencies',
      () {
        final input = [0.0, 0.0, 0.0, 0.0, 0.0];
        final result = EqPresets.interpolateGains(
          input,
          targetBandCount: 5,
          minDb: -12.0,
          maxDb: 12.0,
          bassBoost: 0.8, // 80% bass boost
        );

        expect(result[0], greaterThan(0.0));
        expect(result[1], greaterThan(0.0));
        expect(result[2], equals(0.0)); // Mid stays flat
        expect(result[3], equals(0.0)); // High stays flat
        expect(result[4], equals(0.0));
      },
    );

    test('Custom slider adjustments update _bandGains and persist', () {
      manager.setBandGain(0, 5.5);
      manager.setBandGain(1, 3.0);
      manager.setBandGain(2, -2.0);
      manager.setBandGain(3, 1.5);
      manager.setBandGain(4, 4.0);

      expect(manager.soundPreset, equals('Custom'));
      expect(manager.bandGains[0], equals(5.5));
      expect(manager.bandGains[1], equals(3.0));
      expect(manager.bandGains[2], equals(-2.0));
      expect(manager.bandGains[3], equals(1.5));
      expect(manager.bandGains[4], equals(4.0));

      // Save custom preset
      manager.saveCustomPreset('My Custom Studio', [5.5, 3.0, -2.0, 1.5, 4.0]);
      expect(manager.customPresets.containsKey('My Custom Studio'), isTrue);
      expect(manager.soundPreset, equals('My Custom Studio'));

      // Switch to Pop then switch back to My Custom Studio
      manager.setSoundPreset('Pop');
      expect(manager.soundPreset, equals('Pop'));

      manager.setSoundPreset('My Custom Studio');
      expect(manager.soundPreset, equals('My Custom Studio'));
      expect(manager.bandGains[0], equals(5.5));

      // Reset equalizer
      manager.resetEqualizer();
      expect(manager.soundPreset, equals('Normal'));
      expect(manager.bandGains.every((g) => g == 0.0), isTrue);
      expect(manager.bassBoost, equals(0.0));
      expect(manager.virtualizer, equals(0.0));
      expect(manager.loudnessGain, equals(0.0));
    });
  });
}
