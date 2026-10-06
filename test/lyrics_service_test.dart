import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/lyrics_service.dart';

void main() {
  group('LyricsService Unit Tests', () {
    late LyricsService service;

    setUp(() {
      service = LyricsService.instance;
      service.clearCache();
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

    group('request caching', () {
      const noLyricsSong = Song(
        id: 'song_no_lyrics',
        title: 'Instrumental Track',
        artist: 'Nobody',
        duration: Duration(seconds: 120),
        audioUrl: 'https://example.com/a.mp3',
        coverUrl: 'https://example.com/a.jpg',
      );

      tearDown(() => service.remoteFetcher = null);

      test('a failed lookup is remembered and not requested again', () async {
        var calls = 0;
        service.remoteFetcher =
            ({
              required String title,
              required String artist,
              int? durationSeconds,
            }) async {
              calls++;
              return null;
            };

        expect(await service.getLyrics(noLyricsSong), isNull);
        expect(await service.getLyrics(noLyricsSong), isNull);
        expect(await service.getLyrics(noLyricsSong), isNull);
        expect(calls, 1);
      });

      test('forceRefresh bypasses the remembered failure', () async {
        var calls = 0;
        service.remoteFetcher =
            ({
              required String title,
              required String artist,
              int? durationSeconds,
            }) async {
              calls++;
              return null;
            };

        await service.getLyrics(noLyricsSong);
        await service.getLyrics(noLyricsSong, forceRefresh: true);
        expect(calls, 2);
      });

      test('concurrent callers share one request', () async {
        var calls = 0;
        final gate = Completer<String?>();
        service.remoteFetcher =
            ({
              required String title,
              required String artist,
              int? durationSeconds,
            }) {
              calls++;
              return gate.future;
            };

        final a = service.getLyrics(noLyricsSong);
        final b = service.getLyrics(noLyricsSong);
        gate.complete('[00:01.00]Hello');

        expect(await a, '[00:01.00]Hello');
        expect(await b, '[00:01.00]Hello');
        expect(calls, 1);
      });
    });

    test('isSynced differentiates synchronized LRC from plain text', () {
      const synced = '[00:05.10]First line\n[00:10.20]Second line';
      const plain = 'Just some words\nwithout timestamps';

      expect(service.isSynced(synced), isTrue);
      expect(service.isSynced(plain), isFalse);
      expect(service.isSynced(''), isFalse);
      expect(service.isSynced(null), isFalse);
    });

    group('request caching', () {
      const noLyricsSong = Song(
        id: 'song_no_lyrics',
        title: 'Instrumental',
        artist: 'Nobody',
        duration: Duration(seconds: 120),
        audioUrl: 'https://example.com/i.mp3',
        coverUrl: 'https://example.com/i.jpg',
      );

      tearDown(() {
        service.remoteFetcher = null;
        service.clearCache();
      });

      test('a failed lookup is remembered and not re-requested', () async {
        var calls = 0;
        service.remoteFetcher =
            ({
              required String title,
              required String artist,
              int? durationSeconds,
            }) async {
              calls++;
              return null;
            };

        expect(await service.getLyrics(noLyricsSong), isNull);
        expect(await service.getLyrics(noLyricsSong), isNull);
        expect(await service.getLyrics(noLyricsSong), isNull);
        expect(calls, 1);
      });

      test('forceRefresh bypasses the remembered failure', () async {
        var calls = 0;
        service.remoteFetcher =
            ({
              required String title,
              required String artist,
              int? durationSeconds,
            }) async {
              calls++;
              return calls >= 2 ? '[00:01.00]Found it' : null;
            };

        expect(await service.getLyrics(noLyricsSong), isNull);
        final refreshed = await service.getLyrics(
          noLyricsSong,
          forceRefresh: true,
        );
        expect(refreshed, contains('Found it'));
        expect(calls, 2);
      });

      test('concurrent callers share one in-flight request', () async {
        var calls = 0;
        final gate = Completer<String?>();
        service.remoteFetcher =
            ({
              required String title,
              required String artist,
              int? durationSeconds,
            }) {
              calls++;
              return gate.future;
            };

        final first = service.getLyrics(noLyricsSong);
        final second = service.getLyrics(noLyricsSong);
        gate.complete('[00:02.00]Shared');

        expect(await first, contains('Shared'));
        expect(await second, contains('Shared'));
        expect(calls, 1);
      });
    });
  });
}
