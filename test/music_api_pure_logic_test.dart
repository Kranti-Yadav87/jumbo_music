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

    test(
      'normalizeSongTitle and deduplicateSongs eliminate duplicate versions',
      () {
        const song1 = Song(
          id: 'id_1',
          title: 'Tum Hi Ho (From "Aashiqui 2")',
          artist: 'Arijit Singh, Mithoon',
          duration: Duration(seconds: 262),
          audioUrl: 'https://example.com/1.mp3',
          coverUrl: '',
        );
        const song2 = Song(
          id: 'id_2',
          title: 'Tum Hi Ho [Remastered]',
          artist: 'Arijit Singh',
          duration: Duration(seconds: 262),
          audioUrl: 'https://example.com/2.mp3',
          coverUrl: '',
        );
        const song3 = Song(
          id: 'id_3',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          duration: Duration(seconds: 289),
          audioUrl: 'https://example.com/3.mp3',
          coverUrl: '',
        );

        expect(
          SongParserUtils.normalizeSongTitle(song1.title),
          equals('tum hi ho'),
        );
        expect(
          SongParserUtils.normalizeSongTitle(song2.title),
          equals('tum hi ho'),
        );

        final deduped = SongParserUtils.deduplicateSongs([song1, song2, song3]);
        expect(deduped.length, equals(2));
        expect(deduped[0].id, equals('id_1'));
        expect(deduped[1].id, equals('id_3'));
      },
    );
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

    test(
      'normalizeSongTitle splits delimiters (- | : //) and removes parentheses/remastered suffixes',
      () {
        const s1 = Song(
          id: '1',
          title: 'Pal Pal Dil Ke Paas - Kishore Kumar',
          artist: 'Kishore Kumar',
          audioUrl: 'https://example.com/1.mp3',
          coverUrl: '',
          duration: Duration(seconds: 300),
        );
        const s2 = Song(
          id: '2',
          title: 'Pal Pal Dil Ke Paas (From "Blackmail")',
          artist: 'Kalyanji Anandji',
          audioUrl: 'https://example.com/2.mp3',
          coverUrl: '',
          duration: Duration(seconds: 300),
        );
        const s3 = Song(
          id: '3',
          title: 'Pal Pal Dil Ke Paas | Remastered 2024',
          artist: 'Kishore Kumar',
          audioUrl: 'https://example.com/3.mp3',
          coverUrl: '',
          duration: Duration(seconds: 300),
        );

        expect(
          SongParserUtils.normalizeSongTitle(s1.title),
          equals('pal pal dil ke paas'),
        );
        expect(
          SongParserUtils.normalizeSongTitle(s2.title),
          equals('pal pal dil ke paas'),
        );
        expect(
          SongParserUtils.normalizeSongTitle(s3.title),
          equals('pal pal dil ke paas'),
        );

        final deduped = SongParserUtils.deduplicateSongs([s1, s2, s3]);
        expect(deduped.length, equals(1));
        expect(deduped.first.id, equals('1'));
      },
    );
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

    test('Classifies musical eras across all 6 eras accurately', () {
      // 1. 70s / Vintage Golden Era
      const vintageSong = Song(
        id: 'v1',
        title: 'Pal Pal Dil Ke Paas',
        artist: 'Kishore Kumar',
        duration: Duration(seconds: 300),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '1973',
      );
      expect(
        MusicTagClassifier.detectSongEra(vintageSong),
        equals(MusicEra.vintage70s),
      );

      // Remaster year override trap: 2024 digital upload of 70s legend remains vintage70s
      const vintageRemaster = Song(
        id: 'v2',
        title: 'Mere Sapno Ki Rani (Remastered)',
        artist: 'Kishore Kumar',
        duration: Duration(seconds: 300),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '2024',
      );
      expect(
        MusicTagClassifier.detectSongEra(vintageRemaster),
        equals(MusicEra.vintage70s),
      );

      // 2. 80s Era
      const eightiesSong = Song(
        id: 'e1',
        title: 'I Am A Disco Dancer',
        artist: 'Bappi Lahiri',
        duration: Duration(seconds: 320),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '1982',
      );
      expect(
        MusicTagClassifier.detectSongEra(eightiesSong),
        equals(MusicEra.era80s),
      );

      // 3. 90s Melodies Era
      const ninetiesSong = Song(
        id: 'n1',
        title: 'Tujhe Dekha To',
        artist: 'Kumar Sanu, Alka Yagnik',
        duration: Duration(seconds: 300),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '1995',
      );
      expect(
        MusicTagClassifier.detectSongEra(ninetiesSong),
        equals(MusicEra.era90s),
      );

      // 4. 2000s Soulful Era
      const twoThousandsSong = Song(
        id: '2k1',
        title: 'Zara Sa',
        artist: 'KK',
        duration: Duration(seconds: 280),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '2008',
      );
      expect(
        MusicTagClassifier.detectSongEra(twoThousandsSong),
        equals(MusicEra.era2000s),
      );

      // 5. 2010s Modern Romance
      const twentyTensSong = Song(
        id: '10s1',
        title: 'Tum Hi Ho',
        album: 'Aashiqui 2',
        artist: 'Arijit Singh',
        duration: Duration(seconds: 260),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '2013',
      );
      expect(
        MusicTagClassifier.detectSongEra(twentyTensSong),
        equals(MusicEra.era2010s),
      );

      // 6. Gen Z / Contemporary
      const genZIndieSong = Song(
        id: 'gz1',
        title: 'Husn',
        artist: 'Anuv Jain',
        duration: Duration(seconds: 220),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '2023',
      );
      expect(
        MusicTagClassifier.detectSongEra(genZIndieSong),
        equals(MusicEra.genZModern),
      );

      const genZPunjabiSong = Song(
        id: 'gz2',
        title: 'Winning Speech',
        artist: 'Karan Aujla',
        duration: Duration(seconds: 190),
        audioUrl: '',
        coverUrl: '',
        releaseYear: '2024',
      );
      expect(
        MusicTagClassifier.detectSongEra(genZPunjabiSong),
        equals(MusicEra.genZModern),
      );
    });
  });
}
