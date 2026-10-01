import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';

void main() {
  group('Song Model Tests', () {
    test('Correctly serializes to and deserializes from JSON', () {
      const song = Song(
        id: 'track_101',
        title: 'Channa Mereya',
        artist: 'Arijit Singh',
        album: 'Ae Dil Hai Mushkil',
        duration: Duration(minutes: 4, seconds: 49),
        audioUrl: 'https://cdn.jumbomusic.app/audio/channa.mp3',
        coverUrl: 'https://cdn.jumbomusic.app/art/channa.jpg',
        genre: 'Bollywood',
        language: 'Hindi',
        lyrics: '[00:10.00] Acha chalta hoon...',
        isFavorite: true,
        releaseYear: '2016',
        quality: '320 kbps HD',
      );

      final json = song.toJson();
      final fromJson = Song.fromJson(json);

      expect(fromJson.id, equals('track_101'));
      expect(fromJson.title, equals('Channa Mereya'));
      expect(fromJson.artist, equals('Arijit Singh'));
      expect(fromJson.duration.inSeconds, equals(289));
      expect(fromJson.formattedDuration, equals('4:49'));
      expect(fromJson.isFavorite, isTrue);
    });

    test('Formatted duration handles edge cases properly', () {
      const songShort = Song(
        id: '1',
        title: 'Jingle',
        artist: 'Artist',
        duration: Duration(seconds: 5),
        audioUrl: '',
        coverUrl: '',
      );
      expect(songShort.formattedDuration, equals('0:05'));

      const songLong = Song(
        id: '2',
        title: 'Symphony',
        artist: 'Artist',
        duration: Duration(minutes: 12, seconds: 3),
        audioUrl: '',
        coverUrl: '',
      );
      expect(songLong.formattedDuration, equals('12:03'));
    });
  });
}
