import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/jam/jam_room_helper.dart';

void main() {
  group('JamRoomHelper Tests', () {
    test(
      'generateRoomCode produces JUMBO-XXXXXX format with 6 valid characters',
      () {
        final code = JamRoomHelper.generateRoomCode();
        expect(code.startsWith('JUMBO-'), isTrue);
        expect(code.length, equals(12));

        final suffix = code.substring(6);
        expect(suffix.length, equals(6));

        // Check characters are in charset and exclude 0, O, 1, I, L
        const validChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
        for (final char in suffix.split('')) {
          expect(validChars.contains(char), isTrue);
          expect(['0', 'O', '1', 'I', 'L'].contains(char), isFalse);
        }
      },
    );

    test(
      'generateRoomCode produces unique room codes across multiple calls',
      () {
        final codes = <String>{};
        for (int i = 0; i < 50; i++) {
          codes.add(JamRoomHelper.generateRoomCode());
        }
        expect(codes.length, equals(50));
      },
    );

    test('isValidRoomCode accurately validates room codes', () {
      expect(JamRoomHelper.isValidRoomCode('JUMBO-ABC234'), isTrue);
      expect(JamRoomHelper.isValidRoomCode('jumbo-abc234'), isTrue);
      expect(JamRoomHelper.isValidRoomCode('ABC234'), isTrue);
      expect(JamRoomHelper.isValidRoomCode('  jumbo-abc234  '), isTrue);

      // Invalid lengths / characters
      expect(JamRoomHelper.isValidRoomCode(''), isFalse);
      expect(JamRoomHelper.isValidRoomCode('JUMBO-'), isFalse);
      expect(JamRoomHelper.isValidRoomCode('JUMBO-AB'), isFalse);
      expect(JamRoomHelper.isValidRoomCode('JUMBO-ABC2345'), isFalse);
      // Ambiguous characters: 0, O, 1, I, L
      expect(JamRoomHelper.isValidRoomCode('JUMBO-ABCO12'), isFalse);
      expect(JamRoomHelper.isValidRoomCode('JUMBO-ABC123'), isFalse);
      expect(JamRoomHelper.isValidRoomCode('JUMBO-ABCI23'), isFalse);
      expect(JamRoomHelper.isValidRoomCode('JUMBO-ABCL23'), isFalse);
    });

    test(
      'normalizeRoomCode formats code to standard JUMBO-XXXXXX uppercase',
      () {
        expect(
          JamRoomHelper.normalizeRoomCode('abc234'),
          equals('JUMBO-ABC234'),
        );
        expect(
          JamRoomHelper.normalizeRoomCode('jumbo-abc234'),
          equals('JUMBO-ABC234'),
        );
        expect(
          JamRoomHelper.normalizeRoomCode('  JUMBO-XYZ999  '),
          equals('JUMBO-XYZ999'),
        );
      },
    );
  });
}
