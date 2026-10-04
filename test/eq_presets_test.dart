import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/eq_presets.dart';

void main() {
  group('EqPresets', () {
    test('Normal preset is flat', () {
      final g = EqPresets.gainsFor(
        'Normal',
        bandCount: 5,
        minDb: -15,
        maxDb: 15,
      );
      expect(g, everyElement(0.0));
    });

    test('Bass Boost raises low bands more than high bands', () {
      final g = EqPresets.gainsFor(
        'Bass Boost',
        bandCount: 5,
        minDb: -15,
        maxDb: 15,
      );
      expect(g.first, greaterThan(0));
      expect(g.first, greaterThan(g.last));
    });

    test('Electronic is a V shape (cut in the middle)', () {
      final g = EqPresets.gainsFor(
        'Electronic',
        bandCount: 5,
        minDb: -15,
        maxDb: 15,
      );
      expect(g[2], lessThan(0));
      expect(g.first, greaterThan(0));
      expect(g.last, greaterThan(0));
    });

    test('Gains never exceed the device range', () {
      for (final name in EqPresets.names) {
        final g = EqPresets.gainsFor(name, bandCount: 10, minDb: -6, maxDb: 6);
        for (final v in g) {
          expect(v, inInclusiveRange(-6, 6));
        }
      }
    });

    test('Handles a single band and unknown presets', () {
      expect(
        EqPresets.gainsFor('Rock', bandCount: 1, minDb: -10, maxDb: 10),
        hasLength(1),
      );
      expect(
        EqPresets.gainsFor('Nope', bandCount: 3, minDb: -10, maxDb: 10),
        everyElement(0.0),
      );
    });
  });
}
