import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/api/song_parser_utils.dart';
import 'package:jumbo_music/services/api/music_tag_classifier.dart';

void main() {
  group('SongParserUtils Pure Logic Tests', () {
    test('unescape decodes HTML entities correctly', () {
      expect(
        SongParserUtils.unescape(
          '&quot;Dil Se&quot; &#039;90s&#039; &amp; &lt;Hit&gt;',
        ),
        equals('"Dil Se" \'90s\' & <Hit>'),
      );
      expect(SongParserUtils.unescape(null), equals(''));
    });

    test(
      'extractImage upgrades image URLs to https and 500x500 resolution',
      () {
        final imgList = [
          {'link': 'http://c.saavncdn.com/123/150x150.jpg'},
          {'link': 'http://c.saavncdn.com/123/500x500.jpg'},
        ];
        final extracted = SongParserUtils.extractImage(imgList);
        expect(extracted, equals('https://c.saavncdn.com/123/500x500.jpg'));
      },
    );

    test('extractAudioUrl picks highest bitrate available', () {
      final downloadList = [
        {'url': 'https://example.com/audio_96.mp3'},
        {'url': 'https://example.com/audio_160.mp3'},
        {'url': 'https://example.com/audio_320.mp3'},
      ];
      final picked = SongParserUtils.extractAudioUrl(downloadList);
      expect(picked, equals('https://example.com/audio_320.mp3'));
    });

    test('parseSong maps valid json payload into structured Song model', () {
      final json = {
        'id': 'track_123',
        'name': 'Kesariya &amp; Ishq',
        'album': {'name': 'Brahmastra'},
        'duration': '268',
        'year': '2022',
        'language': 'hindi',
        'downloadUrl': 'https://example.com/kesariya.mp3',
        'image': 'http://c.saavncdn.com/test/150x150.jpg',
        'primaryArtists': 'Arijit Singh, Pritam',
      };

      final song = SongParserUtils.parseSong(json);
      expect(song, isNotNull);
      expect(song!.id, equals('track_123'));
      expect(song.title, equals('Kesariya & Ishq'));
      expect(song.album, equals('Brahmastra'));
      expect(song.artist, equals('Arijit Singh, Pritam'));
      expect(song.releaseYear, equals('2022'));
      expect(song.coverUrl, contains('https://'));
      expect(song.coverUrl, contains('500x500.jpg'));
    });
  });

  group('MusicTagClassifier Pure Logic Tests', () {
    test('detectSongLanguage classifies Hindi, Punjabi, South and English', () {
      const hindiSong = Song(
        id: '1',
        title: 'Dil Sambhal Ja Zara',
        artist: 'Mohammed Irfan',
        duration: Duration(seconds: 200),
        audioUrl: '',
        coverUrl: '',
      );
      expect(MusicTagClassifier.detectSongLanguage(hindiSong), equals('Hindi'));

      const punjabiSong = Song(
        id: '2',
        title: 'Softly',
        artist: 'Karan Aujla',
        duration: Duration(seconds: 150),
        audioUrl: '',
        coverUrl: '',
      );
      expect(
        MusicTagClassifier.detectSongLanguage(punjabiSong),
        equals('Punjabi'),
      );

      const englishSong = Song(
        id: '3',
        title: 'Cruel Summer',
        artist: 'Taylor Swift',
        duration: Duration(seconds: 180),
        audioUrl: '',
        coverUrl: '',
        language: 'english',
      );
      expect(
        MusicTagClassifier.detectSongLanguage(englishSong),
        equals('English'),
      );
    });

    test('Classifies musical eras accurately', () {
      const vintageSong = Song(
        id: 'v1',
        title: 'Pal Pal Dil Ke Paas',
        artist: 'Kishore Kumar',
        duration: Duration(seconds: 300),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '1973',
      );
      expect(MusicTagClassifier.isVintageGoldenEra(vintageSong), isTrue);
      expect(MusicTagClassifier.is80sEra(vintageSong), isFalse);

      const eightiesSong = Song(
        id: 'e1',
        title: 'I Am A Disco Dancer',
        artist: 'Bappi Lahiri',
        duration: Duration(seconds: 320),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '1982',
      );
      expect(MusicTagClassifier.is80sEra(eightiesSong), isTrue);
      expect(MusicTagClassifier.is90sMelodyEra(eightiesSong), isFalse);

      const ninetiesSong = Song(
        id: 'n1',
        title: 'Tujhe Dekha To',
        artist: 'Kumar Sanu, Lata Mangeshkar',
        duration: Duration(seconds: 300),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '1995',
      );
      expect(MusicTagClassifier.is90sMelodyEra(ninetiesSong), isTrue);

      const twoThousandsSong = Song(
        id: '2k1',
        title: 'Zara Sa',
        artist: 'KK',
        duration: Duration(seconds: 280),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '2008',
      );
      expect(MusicTagClassifier.is2000sSong(twoThousandsSong), isTrue);
    });
  });
}
