import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/api/jamendo_search_service.dart';

void main() {
  test('parseTracks maps a Jamendo response to Song objects', () {
    final songs = JamendoSearchService.parseTracks({
      'results': [
        {
          'id': '1234',
          'name': 'Sunrise',
          'artist_name': 'Some Artist',
          'album_name': 'Dawn',
          'duration': 215,
          'releasedate': '2021-05-03',
          'image': 'https://img.example/cover.jpg',
          'audio': 'https://stream.example/1234.mp3',
          'musicinfo': {
            'tags': {
              'genres': ['lofi'],
            },
          },
        },
      ],
    });
    expect(songs, hasLength(1));
    final s = songs.first;
    expect(s.id, 'jamendo_1234');
    expect(s.title, 'Sunrise');
    expect(s.artist, 'Some Artist');
    expect(s.album, 'Dawn');
    expect(s.duration, const Duration(seconds: 215));
    expect(s.releaseYear, '2021');
    expect(s.genre, 'lofi');
    expect(s.audioUrl, 'https://stream.example/1234.mp3');
  });

  test('parseTracks skips entries without audio or title', () {
    final songs = JamendoSearchService.parseTracks({
      'results': [
        {'id': '1', 'name': 'No audio', 'artist_name': 'A'},
        {'id': '2', 'artist_name': 'A', 'audio': 'https://x/2.mp3'},
        'not a map',
      ],
    });
    expect(songs, isEmpty);
  });

  test('parseTracks tolerates unexpected shapes', () {
    expect(JamendoSearchService.parseTracks({}), isEmpty);
    expect(JamendoSearchService.parseTracks({'results': 'oops'}), isEmpty);
  });

  test('service is a no-op without a client id', () async {
    expect(JamendoSearchService.isConfigured, isFalse);
    expect(await JamendoSearchService.search('anything'), isEmpty);
  });
}
