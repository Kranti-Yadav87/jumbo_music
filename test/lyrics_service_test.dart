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

    test('getLyrics returns embedded song lyrics and populates cache', () async {
      const songWithLyrics = Song(
        id: 'song_lrc_1',
        title: 'Channa Mereya',
        artist: 'Arijit Singh',
        duration: Duration(seconds: 289),
        audioUrl: 'https://example.com/cm.mp3',
        coverUrl: 'https://example.com/cm.jpg',
        lyrics: '[00:12.50]Accha chalta hoon\n[00:15.80]Duaaon mein yaad rakhna',
      );

      final result = await service.getLyrics(songWithLyrics);
      expect(result, contains('Accha chalta hoon'));
      expect(service.cache.containsKey('song_lrc_1'), isTrue);
      expect(service.isSynced(result), isTrue);
    });

    test('cacheLyrics and clearCache operate properly', () {
      service.cacheLyrics('song_123', '[00:01.00]Hello world', title: 'Hello', artist: 'Adele');
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
  });
}
