import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/lrc_parser.dart';

void main() {
  group('LrcParser Tests', () {
    test('Correctly parses valid LRC timestamped lines', () {
      const sampleLrc = '''
[00:12.50]Line 1: Starting the journey
[00:25.00]Line 2: The beat drops
[01:05.20]Line 3: Chorus begins
''';

      final lines = LrcParser.parse(sampleLrc);

      expect(lines.length, equals(3));
      expect(lines[0].timestamp.inMilliseconds, equals(12500));
      expect(lines[0].text, equals('Line 1: Starting the journey'));
      expect(lines[1].timestamp.inMilliseconds, equals(25000));
      expect(lines[1].text, equals('Line 2: The beat drops'));
      expect(lines[2].timestamp.inMilliseconds, equals(65200));
      expect(lines[2].text, equals('Line 3: Chorus begins'));
    });

    test('Finds correct active index based on audio position', () {
      const sampleLrc = '''
[00:10.00]First verse
[00:20.00]Second verse
[00:30.00]Chorus
''';

      final lines = LrcParser.parse(sampleLrc);

      // Before first timestamp
      expect(
        LrcParser.findActiveIndex(lines, const Duration(seconds: 5)),
        equals(0),
      );

      // Exactly at second timestamp
      expect(
        LrcParser.findActiveIndex(lines, const Duration(seconds: 20)),
        equals(1),
      );

      // In between second and third timestamp
      expect(
        LrcParser.findActiveIndex(lines, const Duration(seconds: 25)),
        equals(1),
      );

      // After last timestamp
      expect(
        LrcParser.findActiveIndex(lines, const Duration(seconds: 45)),
        equals(2),
      );
    });

    test('Gracefully converts plain lyrics without timestamps', () {
      const plainLyrics = '''
First line of the song
Second line of the song
Third line of the song
''';

      final lines = LrcParser.parse(
        plainLyrics,
        totalDuration: const Duration(seconds: 90),
      );

      expect(lines.length, equals(3));
      expect(lines[0].timestamp, equals(Duration.zero));
      expect(lines[1].timestamp.inSeconds, equals(30));
      expect(lines[2].timestamp.inSeconds, equals(60));
    });

    test('Handles empty or null input gracefully', () {
      expect(LrcParser.parse(null), isEmpty);
      expect(LrcParser.parse(''), isEmpty);
      expect(LrcParser.parse('   '), isEmpty);
    });
  });
}
