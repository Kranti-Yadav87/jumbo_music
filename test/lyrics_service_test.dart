import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/lyrics_service.dart';
import 'package:jumbo_music/services/lrc_parser.dart';

void main() {
  group('LyricsService Unit Tests', () {
    late LyricsService service;

    setUp(() {
      service = LyricsService.instance;
      service.clearCache();
      LyricsService.mockHttpClient = null;
    });

    tearDown(() {
      LyricsService.mockHttpClient = null;
    });

    test(
      'getLyrics returns embedded song lyrics and populates cache',
      () async {
        const songWithLyrics = Song(
          id: 'song_lrc_1',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          duration: Duration(seconds: 289),
          audioUrl: 'https://example.com/cm.mp3',
          coverUrl: 'https://example.com/cm.jpg',
          lyrics:
              '[00:12.50]Accha chalta hoon\n[00:15.80]Duaaon mein yaad rakhna',
        );

        final result = await service.getLyrics(songWithLyrics);
        expect(result, contains('Accha chalta hoon'));
        expect(service.cache.containsKey('song_lrc_1'), isTrue);
        expect(service.isSynced(result), isTrue);

        final fetchResult = await service.fetch(songWithLyrics);
        expect(fetchResult, equals(result));
      },
    );

    test('cacheLyrics and clearCache operate properly', () {
      service.cacheLyrics(
        'song_123',
        '[00:01.00]Hello world',
        title: 'Hello',
        artist: 'Adele',
      );
      expect(service.cache.containsKey('song_123'), isTrue);

      service.clearCache();
      expect(service.cache.isEmpty, isTrue);
    });

    test('isSynced differentiates synchronized LRC from plain text', () {
      const synced = '[00:05.10]First line\n[00:10.20]Second line';
      const plain = 'Just some words\nwithout timestamps';

      expect(service.isSynced(synced), isTrue);
      expect(service.isSynced(plain), isFalse);
      expect(service.isSynced(''), isFalse);
      expect(service.isSynced(null), isFalse);
    });

    test('LrcParser.isSynchronized detects timestamps correctly', () {
      expect(LrcParser.isSynchronized('[01:14.20] Lyric line'), isTrue);
      expect(LrcParser.isSynchronized('Just plain line'), isFalse);
      expect(LrcParser.isSynchronized(null), isFalse);
    });

    test(
      'Multi-artist candidate queries vocalist before composer when composer is first',
      () async {
        // Mock client that returns 404 for composer Mithoon, but 200 with synced lyrics for Arijit Singh
        LyricsService.mockHttpClient = MockClient((request) async {
          final path = request.url.path;
          final params = request.url.queryParameters;

          if (path == '/api/get') {
            final artist = params['artist_name'] ?? '';
            if (artist.contains('Arijit Singh')) {
              return http.Response(
                jsonEncode({
                  'id': 101,
                  'trackName': 'Tum Hi Ho',
                  'artistName': 'Arijit Singh',
                  'instrumental': false,
                  'syncedLyrics': '[00:11.20]Hum tere bin ab reh nahi sakte',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            } else if (artist.contains('Mithoon')) {
              // Mithoon's entry is marked instrumental
              return http.Response(
                jsonEncode({
                  'id': 102,
                  'trackName': 'Tum Hi Ho',
                  'artistName': 'Mithoon',
                  'instrumental': true,
                  'syncedLyrics': null,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
          }
          return http.Response('Not found', 404);
        });

        final lyrics = await service.fetchLyricsByQuery(
          title: 'Tum Hi Ho',
          artist: 'Mithoon, Arijit Singh',
          durationSeconds: 262,
        );

        expect(lyrics, isNotNull);
        expect(lyrics, contains('Hum tere bin ab reh nahi sakte'));
      },
    );

    test(
      'Rejects mismatched mashup songs from LRCLIB search (e.g. Pachtaoge vs Tum Hi Ho)',
      () async {
        // Mock client that returns a search list where first item has mismatched track name
        LyricsService.mockHttpClient = MockClient((request) async {
          if (request.url.path == '/api/search') {
            return http.Response(
              jsonEncode([
                {
                  'id': 201,
                  'trackName': 'Pachtaoge-Tum Hi Ho Lofi Mix',
                  'name': 'Pachtaoge-Tum Hi Ho Lofi Mix',
                  'artistName': 'Arijit Singh',
                  'instrumental': false,
                  'plainLyrics': 'O mujhe chhodkar jo tum jaaoge',
                },
                {
                  'id': 202,
                  'trackName': 'Tum Hi Ho',
                  'name': 'Tum Hi Ho',
                  'artistName': 'Arijit Singh',
                  'instrumental': false,
                  'syncedLyrics': '[00:11.20]Hum tere bin ab reh nahi sakte',
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not found', 404);
        });

        final lyrics = await service.fetchLyricsByQuery(
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          durationSeconds: 262,
        );

        expect(lyrics, isNotNull);
        // Must NOT contain Pachtaoge lyrics! Must pick the matching Tum Hi Ho track!
        expect(lyrics, isNot(contains('O mujhe chhodkar')));
        expect(lyrics, contains('Hum tere bin ab reh nahi sakte'));
      },
    );

    test(
      'Falls back to JioSaavn official lyrics when LRCLIB has no match',
      () async {
        LyricsService.mockHttpClient = MockClient((request) async {
          final host = request.url.host;
          final params = request.url.queryParameters;

          if (host == 'lrclib.net') {
            return http.Response('Not found', 404);
          }

          if (host == 'www.jiosaavn.com' &&
              params['__call'] == 'lyrics.getLyrics') {
            return http.Response(
              jsonEncode({
                'lyrics':
                    'Hum Tere Bin Ab Reh Nahi Sakte<br>Tere Bina Kya Wajood Mera<br>',
                'lyrics_copyright': 'Lyrics powered by JioSaavn',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('Not found', 404);
        });

        final lyrics = await service.fetchLyricsByQuery(
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          songId: 'aRZbUYD7',
        );

        expect(lyrics, isNotNull);
        expect(lyrics, contains('Hum Tere Bin Ab Reh Nahi Sakte'));
        expect(lyrics, isNot(contains('<br>'))); // HTML cleaned
      },
    );
  });
}
