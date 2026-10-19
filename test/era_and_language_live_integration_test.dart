import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/api/music_tag_classifier.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/recommendation/ai_recommendation_engine.dart';
import 'package:jumbo_music/services/api/song_parser_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Era and Language Live End-to-End Isolation Tests', () {
    late AiRecommendationEngine engine;

    setUp(() async {
      engine = AiRecommendationEngine.instance;
      engine.resetForTesting();
      await DatabaseService.instance.switchUserScope('test_era_lang_user');
      await DatabaseService.instance.clearHistory();
    });

    test(
      '1. 70s Vintage Era Invariance (even with 2021-2024 compilation dates)',
      () {
        const kishore = Song(
          id: 'k1',
          title: 'Mere Sapno Ki Rani',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 290),
          audioUrl: 'https://example.com/k1.mp3',
          coverUrl: '',
          releaseYear: '2021', // Modern compilation date
        );

        const rafi = Song(
          id: 'r1',
          title: 'Gulabi Aankhen',
          artist: 'Mohammed Rafi',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/r1.mp3',
          coverUrl: '',
          releaseYear: '2023', // Modern compilation date
        );

        const mukesh = Song(
          id: 'm1',
          title: 'Jeena Yahan Marna Yahan',
          artist: 'Mukesh',
          duration: Duration(seconds: 240),
          audioUrl: 'https://example.com/m1.mp3',
          coverUrl: '',
          releaseYear: '2022',
        );

        const lataVintage = Song(
          id: 'lv1',
          title: 'Lag Ja Gale',
          artist: 'Lata Mangeshkar',
          duration: Duration(seconds: 250),
          audioUrl: 'https://example.com/lv1.mp3',
          coverUrl: '',
          releaseYear: '2020',
        );

        expect(
          MusicTagClassifier.detectSongEra(kishore),
          equals(MusicEra.vintage70s),
        );
        expect(
          MusicTagClassifier.detectSongEra(rafi),
          equals(MusicEra.vintage70s),
        );
        expect(
          MusicTagClassifier.detectSongEra(mukesh),
          equals(MusicEra.vintage70s),
        );
        expect(
          MusicTagClassifier.detectSongEra(lataVintage),
          equals(MusicEra.vintage70s),
        );

        expect(MusicTagClassifier.detectSongLanguage(kishore), equals('Hindi'));
        expect(MusicTagClassifier.detectSongLanguage(rafi), equals('Hindi'));
      },
    );

    test('2. 80s Era Classification', () {
      const bappi = Song(
        id: 'b1',
        title: 'I Am A Disco Dancer',
        artist: 'Bappi Lahiri',
        duration: Duration(seconds: 300),
        audioUrl: 'https://example.com/b1.mp3',
        coverUrl: '',
        releaseYear: '2022',
      );

      const amitKumar = Song(
        id: 'ak1',
        title: 'Papa Kehte Hain Bada Naam Karega',
        artist: 'Amit Kumar',
        album: 'Qayamat Se Qayamat Tak',
        duration: Duration(seconds: 280),
        audioUrl: 'https://example.com/ak1.mp3',
        coverUrl: '',
        releaseYear: '1988',
      );

      expect(MusicTagClassifier.detectSongEra(bappi), equals(MusicEra.era80s));
      expect(
        MusicTagClassifier.detectSongEra(amitKumar),
        equals(MusicEra.era80s),
      );
    });

    test('3. 90s Melodies Era Invariance', () {
      const sanu = Song(
        id: 's1',
        title: 'Chura Ke Dil Mera',
        artist: 'Kumar Sanu, Alka Yagnik',
        duration: Duration(seconds: 280),
        audioUrl: 'https://example.com/s1.mp3',
        coverUrl: '',
        releaseYear: '2023',
      );

      const udit = Song(
        id: 'u1',
        title: 'Tujhe Dekha To Ye Jaana Sanam',
        artist: 'Udit Narayan, Lata Mangeshkar',
        album: 'Dilwale Dulhania Le Jayenge',
        duration: Duration(seconds: 300),
        audioUrl: 'https://example.com/u1.mp3',
        coverUrl: '',
        releaseYear: '2021',
      );

      expect(MusicTagClassifier.detectSongEra(sanu), equals(MusicEra.era90s));
      expect(MusicTagClassifier.detectSongEra(udit), equals(MusicEra.era90s));
    });

    test('4. 2000s Soulful Era Invariance', () {
      const kk = Song(
        id: 'kk1',
        title: 'Zara Sa',
        artist: 'KK',
        album: 'Jannat',
        duration: Duration(seconds: 290),
        audioUrl: 'https://example.com/kk1.mp3',
        coverUrl: '',
        releaseYear: '2024',
      );

      const luckyAli = Song(
        id: 'la1',
        title: 'O Sanam',
        artist: 'Lucky Ali',
        duration: Duration(seconds: 220),
        audioUrl: 'https://example.com/la1.mp3',
        coverUrl: '',
        releaseYear: '2022',
      );

      expect(MusicTagClassifier.detectSongEra(kk), equals(MusicEra.era2000s));
      expect(
        MusicTagClassifier.detectSongEra(luckyAli),
        equals(MusicEra.era2000s),
      );
    });

    test('5. 2010s Romantic Era Classification', () {
      const arijit2010s = Song(
        id: 'ar1',
        title: 'Tum Hi Ho',
        artist: 'Arijit Singh',
        album: 'Aashiqui 2',
        duration: Duration(seconds: 260),
        audioUrl: 'https://example.com/ar1.mp3',
        coverUrl: '',
        releaseYear: '2013',
      );

      const bekhayali = Song(
        id: 'bk1',
        title: 'Bekhayali',
        artist: 'Sachet Tandon',
        album: 'Kabir Singh',
        duration: Duration(seconds: 370),
        audioUrl: 'https://example.com/bk1.mp3',
        coverUrl: '',
        releaseYear: '2019',
      );

      expect(
        MusicTagClassifier.detectSongEra(arijit2010s),
        equals(MusicEra.era2010s),
      );
      expect(
        MusicTagClassifier.detectSongEra(bekhayali),
        equals(MusicEra.era2010s),
      );
    });

    test('6. Gen Z & Modern Era Classification', () {
      const anuvJain = Song(
        id: 'aj1',
        title: 'Husn',
        artist: 'Anuv Jain',
        duration: Duration(seconds: 215),
        audioUrl: 'https://example.com/aj1.mp3',
        coverUrl: '',
        releaseYear: '2023',
      );

      const karanAujla = Song(
        id: 'ka1',
        title: 'Tauba Tauba',
        artist: 'Karan Aujla',
        duration: Duration(seconds: 200),
        audioUrl: 'https://example.com/ka1.mp3',
        coverUrl: '',
        releaseYear: '2024',
      );

      const animalSong = Song(
        id: 'an1',
        title: 'Pehle Bhi Main',
        artist: 'Vishal Mishra',
        album: 'Animal',
        duration: Duration(seconds: 250),
        audioUrl: 'https://example.com/an1.mp3',
        coverUrl: '',
        releaseYear: '2023',
      );

      expect(
        MusicTagClassifier.detectSongEra(anuvJain),
        equals(MusicEra.genZModern),
      );
      expect(
        MusicTagClassifier.detectSongEra(karanAujla),
        equals(MusicEra.genZModern),
      );
      expect(
        MusicTagClassifier.detectSongEra(animalSong),
        equals(MusicEra.genZModern),
      );
    });

    test('7. English Tracks Identification (Zero False Hindi tagging)', () {
      const starboy = Song(
        id: 'e1',
        title: 'Starboy',
        artist: 'The Weeknd, Daft Punk',
        duration: Duration(seconds: 230),
        audioUrl: 'https://example.com/starboy.mp3',
        coverUrl: '',
        releaseYear: '2016',
      );

      const stay = Song(
        id: 'e2',
        title: 'Stay',
        artist: 'The Kid LAROI, Justin Bieber',
        duration: Duration(seconds: 140),
        audioUrl: 'https://example.com/stay.mp3',
        coverUrl: '',
        releaseYear: '2021',
      );

      const heatWaves = Song(
        id: 'e3',
        title: 'Heat Waves',
        artist: 'Glass Animals',
        duration: Duration(seconds: 238),
        audioUrl: 'https://example.com/heatwaves.mp3',
        coverUrl: '',
        releaseYear: '2020',
      );

      const jamendoTrack = Song(
        id: 'jamendo_12345',
        title: 'Summer Breeze Acoustic',
        artist: 'Indie Artist',
        duration: Duration(seconds: 190),
        audioUrl: 'https://prod-1.storage.jamendo.com/track.mp3',
        coverUrl: '',
        releaseYear: '2023',
      );

      expect(MusicTagClassifier.detectSongLanguage(starboy), equals('English'));
      expect(MusicTagClassifier.detectSongLanguage(stay), equals('English'));
      expect(
        MusicTagClassifier.detectSongLanguage(heatWaves),
        equals('English'),
      );
      expect(
        MusicTagClassifier.detectSongLanguage(jamendoTrack),
        equals('English'),
      );

      expect(MusicTagClassifier.isEnglishSong(starboy), isTrue);
      expect(MusicTagClassifier.isEnglishSong(stay), isTrue);
      expect(MusicTagClassifier.isEnglishSong(heatWaves), isTrue);
      expect(MusicTagClassifier.isEnglishSong(jamendoTrack), isTrue);
    });

    test(
      '8. End-to-End Smart Queue: 70s Kishore Kumar Seed gets STRICTLY 70s tracks (Zero English, Zero Gen Z)',
      () async {
        const kishoreSeed = Song(
          id: 'seed_kishore',
          title: 'Mere Sapno Ki Rani',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 290),
          audioUrl: 'https://example.com/k_seed.mp3',
          coverUrl: '',
          releaseYear: '2021', // compilation
        );

        const rafiCand = Song(
          id: 'c_rafi',
          title: 'Gulabi Aankhen',
          artist: 'Mohammed Rafi',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/r_cand.mp3',
          coverUrl: '',
          releaseYear: '2023',
        );

        const mukeshCand = Song(
          id: 'c_mukesh',
          title: 'Pal Pal Dil Ke Paas',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/m_cand.mp3',
          coverUrl: '',
          releaseYear: '1973',
        );

        const ninetiesSanu = Song(
          id: 'c_sanu',
          title: 'Chura Ke Dil Mera',
          artist: 'Kumar Sanu',
          duration: Duration(seconds: 280),
          audioUrl: 'https://example.com/sanu.mp3',
          coverUrl: '',
          releaseYear: '1994',
        );

        const genZKaran = Song(
          id: 'c_karan',
          title: 'Tauba Tauba',
          artist: 'Karan Aujla',
          duration: Duration(seconds: 200),
          audioUrl: 'https://example.com/karan.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        const englishStay = Song(
          id: 'c_stay',
          title: 'Stay',
          artist: 'The Kid LAROI',
          duration: Duration(seconds: 140),
          audioUrl: 'https://example.com/stay.mp3',
          coverUrl: '',
          releaseYear: '2021',
        );

        final queue = await engine.buildSmartQueue(
          seedSong: kishoreSeed,
          existingQueue: [
            rafiCand,
            mukeshCand,
            ninetiesSanu,
            genZKaran,
            englishStay,
          ],
          targetSize: 10,
        );

        // Verify ONLY 70s Hindi tracks entered the queue
        expect(queue.any((s) => s.id == kishoreSeed.id), isTrue);
        expect(queue.any((s) => s.id == rafiCand.id), isTrue);
        expect(queue.any((s) => s.id == mukeshCand.id), isTrue);

        // Verify cross-era and English tracks were strictly rejected
        expect(queue.any((s) => s.id == ninetiesSanu.id), isFalse);
        expect(queue.any((s) => s.id == genZKaran.id), isFalse);
        expect(queue.any((s) => s.id == englishStay.id), isFalse);

        for (final song in queue) {
          expect(
            MusicTagClassifier.detectSongEra(song),
            equals(MusicEra.vintage70s),
          );
          expect(MusicTagClassifier.detectSongLanguage(song), equals('Hindi'));
        }
      },
    );

    test(
      '9. End-to-End Smart Queue: 90s Kumar Sanu Seed gets STRICTLY 90s tracks (Zero English, Zero 70s, Zero Gen Z)',
      () async {
        const sanuSeed = Song(
          id: 'seed_sanu',
          title: 'Mera Dil Bhi Kitna Pagal Hai',
          artist: 'Kumar Sanu, Alka Yagnik',
          album: 'Saajan',
          duration: Duration(seconds: 320),
          audioUrl: 'https://example.com/sanu_seed.mp3',
          coverUrl: '',
          releaseYear: '2022', // compilation
        );

        const uditCand = Song(
          id: 'c_udit',
          title: 'Tujhe Dekha To Ye Jaana Sanam',
          artist: 'Udit Narayan, Alka Yagnik',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/udit.mp3',
          coverUrl: '',
          releaseYear: '1995',
        );

        const kishoreOld = Song(
          id: 'c_kishore',
          title: 'Roop Tera Mastana',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 240),
          audioUrl: 'https://example.com/roop.mp3',
          coverUrl: '',
          releaseYear: '1969',
        );

        const englishStarboy = Song(
          id: 'c_starboy',
          title: 'Starboy',
          artist: 'The Weeknd',
          duration: Duration(seconds: 230),
          audioUrl: 'https://example.com/starboy.mp3',
          coverUrl: '',
          releaseYear: '2016',
        );

        const modernAnuv = Song(
          id: 'c_anuv',
          title: 'Husn',
          artist: 'Anuv Jain',
          duration: Duration(seconds: 215),
          audioUrl: 'https://example.com/husn.mp3',
          coverUrl: '',
          releaseYear: '2023',
        );

        final queue = await engine.buildSmartQueue(
          seedSong: sanuSeed,
          existingQueue: [uditCand, kishoreOld, englishStarboy, modernAnuv],
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == sanuSeed.id), isTrue);
        expect(queue.any((s) => s.id == uditCand.id), isTrue);

        expect(queue.any((s) => s.id == kishoreOld.id), isFalse);
        expect(queue.any((s) => s.id == englishStarboy.id), isFalse);
        expect(queue.any((s) => s.id == modernAnuv.id), isFalse);

        for (final song in queue) {
          expect(
            MusicTagClassifier.detectSongEra(song),
            equals(MusicEra.era90s),
          );
          expect(MusicTagClassifier.detectSongLanguage(song), equals('Hindi'));
        }
      },
    );

    test(
      '10. End-to-End Smart Queue: English Seed gets STRICTLY English tracks (Zero Hindi/Indian tracks)',
      () async {
        const englishSeed = Song(
          id: 'seed_english',
          title: 'Blinding Lights',
          artist: 'The Weeknd',
          duration: Duration(seconds: 200),
          audioUrl: 'https://example.com/blinding.mp3',
          coverUrl: '',
          releaseYear: '2020',
        );

        const englishCand = Song(
          id: 'c_stay',
          title: 'Stay',
          artist: 'The Kid LAROI, Justin Bieber',
          duration: Duration(seconds: 140),
          audioUrl: 'https://example.com/stay.mp3',
          coverUrl: '',
          releaseYear: '2021',
        );

        const hindiCand = Song(
          id: 'c_hindi',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          duration: Duration(seconds: 260),
          audioUrl: 'https://example.com/tumhiho.mp3',
          coverUrl: '',
          releaseYear: '2013',
        );

        final queue = await engine.buildSmartQueue(
          seedSong: englishSeed,
          existingQueue: [englishCand, hindiCand],
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == englishSeed.id), isTrue);
        expect(queue.any((s) => s.id == englishCand.id), isTrue);
        expect(queue.any((s) => s.id == hindiCand.id), isFalse);

        for (final song in queue) {
          expect(MusicTagClassifier.isEnglishSong(song), isTrue);
        }
      },
    );

    test(
      '11. Bilingual Indian Artists (Prateek Kuhad) English vs Hindi Discrimination',
      () {
        const kuhad100Words = Song(
          id: 'pk_100words',
          title: '100 words',
          artist: 'Prateek Kuhad',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/pk1.mp3',
          coverUrl: '',
          releaseYear: '2018',
        );

        const kuhadMovie = Song(
          id: 'pk_movie',
          title: 'Just Like A Movie',
          artist: 'Prateek Kuhad',
          duration: Duration(seconds: 198),
          audioUrl: 'https://example.com/pk2.mp3',
          coverUrl: '',
          releaseYear: '2022',
        );

        const kuhadPause = Song(
          id: 'pk_pause',
          title: 'Pause',
          artist: 'Prateek Kuhad',
          duration: Duration(seconds: 171),
          audioUrl: 'https://example.com/pk3.mp3',
          coverUrl: '',
          releaseYear: '2020',
        );

        const kuhadAllINeed = Song(
          id: 'pk_allineed',
          title: 'All I Need',
          artist: 'Prateek Kuhad',
          duration: Duration(seconds: 153),
          audioUrl: 'https://example.com/pk4.mp3',
          coverUrl: '',
          releaseYear: '2022',
        );

        const kuhadWithYou = Song(
          id: 'pk_withyou',
          title: 'with you/for you',
          artist: 'Prateek Kuhad',
          duration: Duration(seconds: 180),
          audioUrl: 'https://example.com/pk5.mp3',
          coverUrl: '',
          releaseYear: '2018',
        );

        const kuhadKasoorHindi = Song(
          id: 'pk_kasoor',
          title: 'Kasoor',
          artist: 'Prateek Kuhad',
          duration: Duration(seconds: 195),
          audioUrl: 'https://example.com/pk_kasoor.mp3',
          coverUrl: '',
          releaseYear: '2020',
        );

        // Verify English songs are detected as English
        expect(
          MusicTagClassifier.detectSongLanguage(kuhad100Words),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(kuhadMovie),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(kuhadPause),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(kuhadAllINeed),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(kuhadWithYou),
          equals('English'),
        );

        expect(MusicTagClassifier.isEnglishSong(kuhad100Words), isTrue);
        expect(MusicTagClassifier.isEnglishSong(kuhadMovie), isTrue);
        expect(MusicTagClassifier.isEnglishSong(kuhadPause), isTrue);
        expect(MusicTagClassifier.isEnglishSong(kuhadAllINeed), isTrue);
        expect(MusicTagClassifier.isEnglishSong(kuhadWithYou), isTrue);

        // Verify genuine Hindi songs by same artist are detected as Hindi
        expect(
          MusicTagClassifier.detectSongLanguage(kuhadKasoorHindi),
          equals('Hindi'),
        );
        expect(MusicTagClassifier.isEnglishSong(kuhadKasoorHindi), isFalse);
      },
    );

    test(
      '12. End-to-End: SAZA (King) Seed gets ZERO English Prateek Kuhad songs & Artist Diversity Cap is enforced',
      () async {
        const sazaSeed = Song(
          id: 'saza',
          title: 'SAZA',
          artist: 'King, MC Heam',
          duration: Duration(seconds: 220),
          audioUrl: 'https://example.com/saza.mp3',
          coverUrl: '',
          releaseYear: '2023',
        );

        final candidates = [
          const Song(
            id: 'pk_1',
            title: '100 words',
            artist: 'Prateek Kuhad',
            duration: Duration(seconds: 210),
            audioUrl: 'https://example.com/pk1.mp3',
            coverUrl: '',
            releaseYear: '2020',
          ),
          const Song(
            id: 'pk_2',
            title: 'Just Like A Movie',
            artist: 'Prateek Kuhad',
            duration: Duration(seconds: 198),
            audioUrl: 'https://example.com/pk2.mp3',
            coverUrl: '',
            releaseYear: '2022',
          ),
          const Song(
            id: 'pk_3',
            title: 'Pause',
            artist: 'Prateek Kuhad',
            duration: Duration(seconds: 171),
            audioUrl: 'https://example.com/pk3.mp3',
            coverUrl: '',
            releaseYear: '2020',
          ),
          const Song(
            id: 'pk_4',
            title: 'All I Need',
            artist: 'Prateek Kuhad',
            duration: Duration(seconds: 153),
            audioUrl: 'https://example.com/pk4.mp3',
            coverUrl: '',
            releaseYear: '2022',
          ),
          const Song(
            id: 'hindi_anuv',
            title: 'Arz Kiya Hai',
            artist: 'Anuv Jain',
            duration: Duration(seconds: 294),
            audioUrl: 'https://example.com/arz.mp3',
            coverUrl: '',
            releaseYear: '2023',
          ),
          const Song(
            id: 'hindi_zaalima',
            title: 'Zaalima',
            artist: 'Arijit Singh, Harshdeep Kaur',
            duration: Duration(seconds: 299),
            audioUrl: 'https://example.com/zaalima.mp3',
            coverUrl: '',
            releaseYear: '2020',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: sazaSeed,
          existingQueue: candidates,
          targetSize: 10,
        );

        // Verify that NO English songs by Prateek Kuhad entered the queue
        expect(queue.any((s) => s.id == 'pk_1'), isFalse);
        expect(queue.any((s) => s.id == 'pk_2'), isFalse);
        expect(queue.any((s) => s.id == 'pk_3'), isFalse);
        expect(queue.any((s) => s.id == 'pk_4'), isFalse);

        // Verify all songs in queue are strictly Hindi
        for (final s in queue) {
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
          expect(MusicTagClassifier.isEnglishSong(s), isFalse);
        }
      },
    );

    test(
      '13. 2010s Hindi Seed gets STRICTLY 2010s Hindi tracks (Zero 90s, Zero 2000s, Zero Gen Z)',
      () async {
        const seed2010s = Song(
          id: 'tum_hi_ho',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          duration: Duration(seconds: 262),
          audioUrl: 'https://example.com/tumhiho.mp3',
          coverUrl: '',
          releaseYear: '2013',
        );

        final mixedCandidates = [
          const Song(
            id: 'sanu_90s',
            title: 'Mera Dil Bhi Kitna Pagal Hai',
            artist: 'Kumar Sanu',
            album: 'Saajan',
            duration: Duration(seconds: 320),
            audioUrl: 'https://example.com/s1.mp3',
            coverUrl: '',
            releaseYear: '1991',
          ),
          const Song(
            id: 'kk_2000s',
            title: 'Zara Sa',
            artist: 'KK',
            album: 'Jannat',
            duration: Duration(seconds: 300),
            audioUrl: 'https://example.com/kk.mp3',
            coverUrl: '',
            releaseYear: '2008',
          ),
          const Song(
            id: 'arijit_2010s_1',
            title: 'Channa Mereya',
            artist: 'Arijit Singh',
            album: 'Ae Dil Hai Mushkil',
            duration: Duration(seconds: 289),
            audioUrl: 'https://example.com/cm.mp3',
            coverUrl: '',
            releaseYear: '2016',
          ),
          const Song(
            id: 'mohit_2010s_2',
            title: 'Tum Ho',
            artist: 'Mohit Chauhan',
            album: 'Rockstar',
            duration: Duration(seconds: 318),
            audioUrl: 'https://example.com/th.mp3',
            coverUrl: '',
            releaseYear: '2011',
          ),
          const Song(
            id: 'genz_2024',
            title: 'O Maahi',
            artist: 'Arijit Singh',
            album: 'Dunki',
            duration: Duration(seconds: 233),
            audioUrl: 'https://example.com/om.mp3',
            coverUrl: '',
            releaseYear: '2024',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: seed2010s,
          existingQueue: mixedCandidates,
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == 'sanu_90s'), isFalse);
        expect(queue.any((s) => s.id == 'kk_2000s'), isFalse);
        expect(queue.any((s) => s.id == 'genz_2024'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2010s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '14. 2000s Hindi Seed gets STRICTLY 2000s Hindi tracks (Zero 90s, Zero 2010s, Zero Gen Z)',
      () async {
        const seed2000s = Song(
          id: 'kk_alvida',
          title: 'Alvida',
          artist: 'KK',
          album: 'Life in a Metro',
          duration: Duration(seconds: 340),
          audioUrl: 'https://example.com/alvida.mp3',
          coverUrl: '',
          releaseYear: '2007',
        );

        final mixedCandidates = [
          const Song(
            id: 'kumar_90s',
            title: 'Dheere Dheere Se Meri Zindagi',
            artist: 'Kumar Sanu',
            album: 'Aashiqui',
            duration: Duration(seconds: 330),
            audioUrl: 'https://example.com/dd.mp3',
            coverUrl: '',
            releaseYear: '1990',
          ),
          const Song(
            id: 'kk_2000s_2',
            title: 'Beete Lamhe',
            artist: 'KK',
            album: 'The Train',
            duration: Duration(seconds: 310),
            audioUrl: 'https://example.com/bl.mp3',
            coverUrl: '',
            releaseYear: '2007',
          ),
          const Song(
            id: 'sonu_2000s',
            title: 'Kal Ho Naa Ho',
            artist: 'Sonu Nigam',
            album: 'Kal Ho Naa Ho',
            duration: Duration(seconds: 320),
            audioUrl: 'https://example.com/khnh.mp3',
            coverUrl: '',
            releaseYear: '2003',
          ),
          const Song(
            id: 'arijit_2010s',
            title: 'Muskurane',
            artist: 'Arijit Singh',
            album: 'Citylights',
            duration: Duration(seconds: 330),
            audioUrl: 'https://example.com/musk.mp3',
            coverUrl: '',
            releaseYear: '2014',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: seed2000s,
          existingQueue: mixedCandidates,
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == 'kumar_90s'), isFalse);
        expect(queue.any((s) => s.id == 'arijit_2010s'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2000s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '15. 2010s English Seed ("Ocean" - Anuv Jain) gets strictly 2010s English tracks',
      () async {
        const oceanSeed = Song(
          id: 'EDxA6Ka6',
          title: 'Ocean',
          artist: 'Anuv Jain',
          album: 'Ocean',
          duration: Duration(seconds: 220),
          audioUrl: 'https://example.com/ocean.mp3',
          coverUrl: '',
          releaseYear: '2018',
        );

        final mixedCandidates = [
          const Song(
            id: 'anuv_hindi_baarishein',
            title: 'Baarishein',
            artist: 'Anuv Jain',
            duration: Duration(seconds: 210),
            audioUrl: 'https://example.com/baarishein.mp3',
            coverUrl: '',
            releaseYear: '2016',
          ),
          const Song(
            id: 'sheeran_2010s',
            title: 'Photograph',
            artist: 'Ed Sheeran',
            duration: Duration(seconds: 258),
            audioUrl: 'https://example.com/photo.mp3',
            coverUrl: '',
            releaseYear: '2014',
          ),
          const Song(
            id: 'swift_2010s',
            title: 'Style',
            artist: 'Taylor Swift',
            duration: Duration(seconds: 231),
            audioUrl: 'https://example.com/style.mp3',
            coverUrl: '',
            releaseYear: '2014',
          ),
          const Song(
            id: 'dua_genz',
            title: 'Houdini',
            artist: 'Dua Lipa',
            duration: Duration(seconds: 185),
            audioUrl: 'https://example.com/houdini.mp3',
            coverUrl: '',
            releaseYear: '2024',
          ),
        ];

        expect(
          MusicTagClassifier.detectSongEra(oceanSeed),
          equals(MusicEra.era2010s),
        );
        expect(MusicTagClassifier.isEnglishSong(oceanSeed), isTrue);

        final queue = await engine.buildSmartQueue(
          seedSong: oceanSeed,
          existingQueue: mixedCandidates,
          targetSize: 10,
        );

        // Hindi songs by Anuv Jain must NOT enter English queue
        expect(queue.any((s) => s.id == 'anuv_hindi_baarishein'), isFalse);
        // 2024 Gen Z modern tracks must NOT enter 2010s queue
        expect(queue.any((s) => s.id == 'dua_genz'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2010s),
          );
          expect(MusicTagClassifier.isEnglishSong(s), isTrue);
        }
      },
    );

    test('16. Negative duration formatting returns 0:00 without crashing', () {
      const negativeSong = Song(
        id: 'neg_1',
        title: 'Negative Track',
        artist: 'Test',
        audioUrl: 'https://example.com/audio.mp3',
        coverUrl: '',
        duration: Duration(seconds: -15),
      );
      expect(negativeSong.formattedDuration, equals('0:00'));
    });

    test(
      '17. "Ocean" - Anuv Jain classification invariance without releaseYear or with compilation year',
      () {
        const oceanNoYear = Song(
          id: 'ocean_no_year',
          title: 'Ocean',
          artist: 'Anuv Jain',
          duration: Duration(seconds: 220),
          audioUrl: 'https://example.com/ocean.mp3',
          coverUrl: '',
          releaseYear: '',
        );
        const oceanCompilationYear = Song(
          id: 'ocean_2024',
          title: 'Ocean',
          artist: 'Anuv Jain',
          duration: Duration(seconds: 220),
          audioUrl: 'https://example.com/ocean.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        expect(
          MusicTagClassifier.detectSongEra(oceanNoYear),
          equals(MusicEra.era2010s),
        );
        expect(MusicTagClassifier.isEnglishSong(oceanNoYear), isTrue);
        expect(MusicTagClassifier.isIndieOrSukoonSong(oceanNoYear), isFalse);
        expect(MusicTagClassifier.isGenZModern(oceanNoYear), isFalse);

        expect(
          MusicTagClassifier.detectSongEra(oceanCompilationYear),
          equals(MusicEra.era2010s),
        );
        expect(MusicTagClassifier.isEnglishSong(oceanCompilationYear), isTrue);
        expect(
          MusicTagClassifier.isIndieOrSukoonSong(oceanCompilationYear),
          isFalse,
        );
        expect(MusicTagClassifier.isGenZModern(oceanCompilationYear), isFalse);
      },
    );

    test(
      '18. Sonu Nigam 2000s Era Classification and Strict Queue Isolation (Zero 90s, Zero 2010s, Zero Gen Z)',
      () async {
        const sonuSeed = Song(
          id: 'sonu_khnh',
          title: 'Kal Ho Naa Ho',
          artist: 'Sonu Nigam',
          album: 'Kal Ho Naa Ho',
          duration: Duration(seconds: 320),
          audioUrl: 'https://example.com/khnh.mp3',
          coverUrl: '',
          releaseYear: '',
        );
        const sonuOmShantiOm = Song(
          id: 'sonu_main_agar',
          title: 'Main Agar Kahoon',
          artist: 'Sonu Nigam, Shreya Ghoshal',
          album: 'Om Shanti Om',
          duration: Duration(seconds: 310),
          audioUrl: 'https://example.com/main_agar.mp3',
          coverUrl: '',
        );
        const sonuMainHoonNa = Song(
          id: 'sonu_tumse_milke',
          title: 'Tumse Milke Dil Ka',
          artist: 'Sonu Nigam',
          album: 'Main Hoon Na',
          duration: Duration(seconds: 360),
          audioUrl: 'https://example.com/tumse_milke.mp3',
          coverUrl: '',
        );

        expect(
          MusicTagClassifier.detectSongEra(sonuSeed),
          equals(MusicEra.era2000s),
        );
        expect(
          MusicTagClassifier.detectSongEra(sonuOmShantiOm),
          equals(MusicEra.era2000s),
        );
        expect(
          MusicTagClassifier.detectSongEra(sonuMainHoonNa),
          equals(MusicEra.era2000s),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(sonuSeed),
          equals('Hindi'),
        );

        final mixedCandidates = [
          const Song(
            id: 'sonu_90s_sandese',
            title: 'Sandese Aate Hai',
            artist: 'Sonu Nigam, Roop Kumar Rathod',
            album: 'Border',
            duration: Duration(seconds: 400),
            audioUrl: 'https://example.com/sandese.mp3',
            coverUrl: '',
            releaseYear: '1997',
          ),
          const Song(
            id: 'kk_2000s_zara_sa',
            title: 'Zara Sa',
            artist: 'KK',
            album: 'Jannat',
            duration: Duration(seconds: 300),
            audioUrl: 'https://example.com/zara_sa.mp3',
            coverUrl: '',
            releaseYear: '2008',
          ),
          const Song(
            id: 'arijit_2010s_tum_hi_ho',
            title: 'Tum Hi Ho',
            artist: 'Arijit Singh',
            album: 'Aashiqui 2',
            duration: Duration(seconds: 262),
            audioUrl: 'https://example.com/tum_hi_ho.mp3',
            coverUrl: '',
            releaseYear: '2013',
          ),
          const Song(
            id: 'genz_karan_aujla',
            title: 'Tauba Tauba',
            artist: 'Karan Aujla',
            duration: Duration(seconds: 210),
            audioUrl: 'https://example.com/tauba.mp3',
            coverUrl: '',
            releaseYear: '2024',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: sonuSeed,
          existingQueue: mixedCandidates,
          targetSize: 10,
        );

        // Must include 2000s KK track
        expect(queue.any((s) => s.id == 'kk_2000s_zara_sa'), isTrue);
        // Zero 90s tracks
        expect(queue.any((s) => s.id == 'sonu_90s_sandese'), isFalse);
        // Zero 2010s tracks
        expect(queue.any((s) => s.id == 'arijit_2010s_tum_hi_ho'), isFalse);
        // Zero Gen Z tracks
        expect(queue.any((s) => s.id == 'genz_karan_aujla'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2000s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '19. Arijit Singh 2010s vs Gen Z 2020+ Discrimination and 2010s Queue Purity',
      () async {
        const arijit2010sSeed = Song(
          id: 'arijit_channa',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          album: 'Ae Dil Hai Mushkil',
          duration: Duration(seconds: 289),
          audioUrl: 'https://example.com/channa.mp3',
          coverUrl: '',
          releaseYear: '2016',
        );
        const arijitGenZAnimal = Song(
          id: 'arijit_satranga',
          title: 'Satranga',
          artist: 'Arijit Singh',
          album: 'Animal',
          duration: Duration(seconds: 270),
          audioUrl: 'https://example.com/satranga.mp3',
          coverUrl: '',
          releaseYear: '2023',
        );
        const arijitGenZDunki = Song(
          id: 'arijit_o_maahi',
          title: 'O Maahi',
          artist: 'Arijit Singh',
          album: 'Dunki',
          duration: Duration(seconds: 245),
          audioUrl: 'https://example.com/o_maahi.mp3',
          coverUrl: '',
          releaseYear: '2023',
        );

        expect(
          MusicTagClassifier.detectSongEra(arijit2010sSeed),
          equals(MusicEra.era2010s),
        );
        expect(
          MusicTagClassifier.detectSongEra(arijitGenZAnimal),
          equals(MusicEra.genZModern),
        );
        expect(
          MusicTagClassifier.detectSongEra(arijitGenZDunki),
          equals(MusicEra.genZModern),
        );

        final mixedCandidates = [
          arijitGenZAnimal,
          arijitGenZDunki,
          const Song(
            id: 'mohit_2010s',
            title: 'Hawaa Hawaa',
            artist: 'Mohit Chauhan',
            album: 'Rockstar',
            duration: Duration(seconds: 320),
            audioUrl: 'https://example.com/rockstar.mp3',
            coverUrl: '',
            releaseYear: '2011',
          ),
          const Song(
            id: 'sanu_90s',
            title: 'Mera Dil Bhi Kitna Pagal Hai',
            artist: 'Kumar Sanu',
            album: 'Saajan',
            duration: Duration(seconds: 310),
            audioUrl: 'https://example.com/saajan.mp3',
            coverUrl: '',
            releaseYear: '1991',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: arijit2010sSeed,
          existingQueue: mixedCandidates,
          targetSize: 10,
        );

        // Must include 2010s Mohit Chauhan Rockstar track
        expect(queue.any((s) => s.id == 'mohit_2010s'), isTrue);
        // Zero 90s tracks
        expect(queue.any((s) => s.id == 'sanu_90s'), isFalse);
        // Zero 2023 Gen Z modern Animal/Dunki tracks
        expect(queue.any((s) => s.id == 'arijit_satranga'), isFalse);
        expect(queue.any((s) => s.id == 'arijit_o_maahi'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2010s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '20. 70s Kishore Kumar Seed -> Strictly 70s tracks (Zero English, Zero Gen Z, Zero 90s, Zero 2000s)',
      () async {
        const kishoreSeed = Song(
          id: 'kk_70s_seed',
          title: 'O Mere Dil Ke Chain',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 280),
          audioUrl: 'https://example.com/dil_ke_chain.mp3',
          coverUrl: '',
          releaseYear: '2022', // compilation
        );

        final mixed = [
          const Song(
            id: 'rafi_70s',
            title: 'Chura Liya Hai Tumne',
            artist: 'Mohammed Rafi, Asha Bhosle',
            duration: Duration(seconds: 290),
            audioUrl: 'https://example.com/chura_liya.mp3',
            coverUrl: '',
            releaseYear: '1973',
          ),
          const Song(
            id: 'sanu_90s_cand',
            title: 'Dheere Dheere Se Meri',
            artist: 'Kumar Sanu',
            album: 'Aashiqui',
            duration: Duration(seconds: 310),
            audioUrl: 'https://example.com/dheere.mp3',
            coverUrl: '',
            releaseYear: '1990',
          ),
          const Song(
            id: 'english_cand',
            title: 'Shape of You',
            artist: 'Ed Sheeran',
            duration: Duration(seconds: 233),
            audioUrl: 'https://example.com/shape.mp3',
            coverUrl: '',
            releaseYear: '2017',
          ),
          const Song(
            id: 'genz_cand',
            title: 'Winning Speech',
            artist: 'Karan Aujla',
            duration: Duration(seconds: 200),
            audioUrl: 'https://example.com/winning.mp3',
            coverUrl: '',
            releaseYear: '2024',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: kishoreSeed,
          existingQueue: mixed,
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == 'rafi_70s'), isTrue);
        expect(queue.any((s) => s.id == 'sanu_90s_cand'), isFalse);
        expect(queue.any((s) => s.id == 'english_cand'), isFalse);
        expect(queue.any((s) => s.id == 'genz_cand'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.vintage70s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '21. 90s Kumar Sanu Seed -> Strictly 90s tracks (Zero 70s, Zero 2000s, Zero Gen Z)',
      () async {
        const sanuSeed = Song(
          id: 'sanu_90s_seed',
          title: 'Tujhe Dekha To Yeh Jaana Sanam',
          artist: 'Kumar Sanu, Lata Mangeshkar',
          album: 'Dilwale Dulhania Le Jayenge',
          duration: Duration(seconds: 320),
          audioUrl: 'https://example.com/tujhe_dekha.mp3',
          coverUrl: '',
          releaseYear: '2023', // compilation
        );

        final mixed = [
          const Song(
            id: 'alka_90s',
            title: 'Tip Tip Barsa Paani',
            artist: 'Alka Yagnik, Udit Narayan',
            album: 'Mohra',
            duration: Duration(seconds: 330),
            audioUrl: 'https://example.com/tip_tip.mp3',
            coverUrl: '',
            releaseYear: '1994',
          ),
          const Song(
            id: 'kishore_70s_cand',
            title: 'Yeh Shaam Mastani',
            artist: 'Kishore Kumar',
            duration: Duration(seconds: 270),
            audioUrl: 'https://example.com/shaam.mp3',
            coverUrl: '',
            releaseYear: '1971',
          ),
          const Song(
            id: 'sonu_2000s_cand',
            title: 'Kal Ho Naa Ho',
            artist: 'Sonu Nigam',
            album: 'Kal Ho Naa Ho',
            duration: Duration(seconds: 310),
            audioUrl: 'https://example.com/khnh.mp3',
            coverUrl: '',
            releaseYear: '2003',
          ),
          const Song(
            id: 'arijit_2023_cand',
            title: 'Satranga',
            artist: 'Arijit Singh',
            album: 'Animal',
            duration: Duration(seconds: 260),
            audioUrl: 'https://example.com/satranga.mp3',
            coverUrl: '',
            releaseYear: '2023',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: sanuSeed,
          existingQueue: mixed,
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == 'alka_90s'), isTrue);
        expect(queue.any((s) => s.id == 'kishore_70s_cand'), isFalse);
        expect(queue.any((s) => s.id == 'sonu_2000s_cand'), isFalse);
        expect(queue.any((s) => s.id == 'arijit_2023_cand'), isFalse);

        for (final s in queue) {
          expect(MusicTagClassifier.detectSongEra(s), equals(MusicEra.era90s));
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '22. 2000s KK / Sonu Nigam Seed -> Strictly 2000s tracks (Zero 90s, Zero 2010s, Zero Gen Z)',
      () async {
        const sonuSeed = Song(
          id: 'sonu_2000s_seed',
          title: 'Kal Ho Naa Ho',
          artist: 'Sonu Nigam',
          album: 'Kal Ho Naa Ho',
          duration: Duration(seconds: 320),
          audioUrl: 'https://example.com/khnh.mp3',
          coverUrl: '',
          releaseYear: '2003',
        );

        final mixed = [
          const Song(
            id: 'kk_2000s_cand',
            title: 'Zara Sa',
            artist: 'KK',
            album: 'Jannat',
            duration: Duration(seconds: 300),
            audioUrl: 'https://example.com/zara_sa.mp3',
            coverUrl: '',
            releaseYear: '2008',
          ),
          const Song(
            id: 'sanu_90s_cand',
            title: 'Chura Ke Dil Mera',
            artist: 'Kumar Sanu',
            duration: Duration(seconds: 280),
            audioUrl: 'https://example.com/chura.mp3',
            coverUrl: '',
            releaseYear: '1994',
          ),
          const Song(
            id: 'arijit_2013_cand',
            title: 'Tum Hi Ho',
            artist: 'Arijit Singh',
            album: 'Aashiqui 2',
            duration: Duration(seconds: 260),
            audioUrl: 'https://example.com/tum_hi_ho.mp3',
            coverUrl: '',
            releaseYear: '2013',
          ),
          const Song(
            id: 'genz_2023_cand',
            title: 'Satranga',
            artist: 'Arijit Singh',
            album: 'Animal',
            duration: Duration(seconds: 250),
            audioUrl: 'https://example.com/satranga.mp3',
            coverUrl: '',
            releaseYear: '2023',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: sonuSeed,
          existingQueue: mixed,
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == 'kk_2000s_cand'), isTrue);
        expect(queue.any((s) => s.id == 'sanu_90s_cand'), isFalse);
        expect(queue.any((s) => s.id == 'arijit_2013_cand'), isFalse);
        expect(queue.any((s) => s.id == 'genz_2023_cand'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2000s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '23. 2010s Arijit Singh Seed -> Strictly 2010s tracks (Zero 90s, Zero 2000s, Zero Gen Z)',
      () async {
        const arijit2010Seed = Song(
          id: 'arijit_2010s_seed',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          duration: Duration(seconds: 262),
          audioUrl: 'https://example.com/tum_hi_ho.mp3',
          coverUrl: '',
          releaseYear: '2013',
        );

        final mixed = [
          const Song(
            id: 'arijit_channa_2016',
            title: 'Channa Mereya',
            artist: 'Arijit Singh',
            album: 'Ae Dil Hai Mushkil',
            duration: Duration(seconds: 289),
            audioUrl: 'https://example.com/channa.mp3',
            coverUrl: '',
            releaseYear: '2016',
          ),
          const Song(
            id: 'kk_2000s_cand',
            title: 'Kya Mujhe Pyar Hai',
            artist: 'KK',
            album: 'Woh Lamhe',
            duration: Duration(seconds: 275),
            audioUrl: 'https://example.com/kya_mujhe.mp3',
            coverUrl: '',
            releaseYear: '2006',
          ),
          const Song(
            id: 'sanu_90s_cand',
            title: 'Mera Dil Bhi Kitna Pagal Hai',
            artist: 'Kumar Sanu',
            album: 'Saajan',
            duration: Duration(seconds: 310),
            audioUrl: 'https://example.com/mera_dil.mp3',
            coverUrl: '',
            releaseYear: '1991',
          ),
          const Song(
            id: 'arijit_genz_2023',
            title: 'O Maahi',
            artist: 'Arijit Singh',
            album: 'Dunki',
            duration: Duration(seconds: 233),
            audioUrl: 'https://example.com/o_maahi.mp3',
            coverUrl: '',
            releaseYear: '2023',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: arijit2010Seed,
          existingQueue: mixed,
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == 'arijit_channa_2016'), isTrue);
        expect(queue.any((s) => s.id == 'kk_2000s_cand'), isFalse);
        expect(queue.any((s) => s.id == 'sanu_90s_cand'), isFalse);
        expect(queue.any((s) => s.id == 'arijit_genz_2023'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2010s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('Hindi'));
        }
      },
    );

    test(
      '24. 2010s English Seed ("Ocean" - Anuv Jain) -> Strictly 2010s English tracks (Zero Hindi, Zero 2024 Gen Z)',
      () async {
        const oceanSeed = Song(
          id: 'anuv_ocean_seed',
          title: 'Ocean',
          artist: 'Anuv Jain',
          duration: Duration(seconds: 215),
          audioUrl: 'https://example.com/ocean.mp3',
          coverUrl: '',
          releaseYear: '2018',
        );

        final mixed = [
          const Song(
            id: 'sheeran_2017',
            title: 'Perfect',
            artist: 'Ed Sheeran',
            album: 'Divide',
            duration: Duration(seconds: 263),
            audioUrl: 'https://example.com/perfect.mp3',
            coverUrl: '',
            releaseYear: '2017',
          ),
          const Song(
            id: 'hindi_arijit_cand',
            title: 'Tum Hi Ho',
            artist: 'Arijit Singh',
            album: 'Aashiqui 2',
            duration: Duration(seconds: 260),
            audioUrl: 'https://example.com/tumhiho.mp3',
            coverUrl: '',
            releaseYear: '2013',
          ),
          const Song(
            id: 'hindi_anuv_baarishein',
            title: 'Baarishein',
            artist: 'Anuv Jain',
            duration: Duration(seconds: 200),
            audioUrl: 'https://example.com/baarishein.mp3',
            coverUrl: '',
            releaseYear: '2016',
          ),
          const Song(
            id: 'modern_2024_cand',
            title: 'Espresso',
            artist: 'Sabrina Carpenter',
            duration: Duration(seconds: 175),
            audioUrl: 'https://example.com/espresso.mp3',
            coverUrl: '',
            releaseYear: '2024',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: oceanSeed,
          existingQueue: mixed,
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == 'sheeran_2017'), isTrue);
        expect(queue.any((s) => s.id == 'hindi_arijit_cand'), isFalse);
        expect(queue.any((s) => s.id == 'hindi_anuv_baarishein'), isFalse);
        expect(queue.any((s) => s.id == 'modern_2024_cand'), isFalse);

        for (final s in queue) {
          expect(
            MusicTagClassifier.detectSongEra(s),
            equals(MusicEra.era2010s),
          );
          expect(MusicTagClassifier.detectSongLanguage(s), equals('English'));
        }
      },
    );

    test(
      '25. Absolute Zero Duplication: No track may appear 2 or more times under title variations or different IDs',
      () async {
        const seed = Song(
          id: 'seed_original_id',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          duration: Duration(seconds: 262),
          audioUrl: 'https://example.com/tum1.mp3',
          coverUrl: '',
          releaseYear: '2013',
        );

        final duplicateVariants = [
          const Song(
            id: 'id_variant_1',
            title: 'Tum Hi Ho (From "Aashiqui 2")',
            artist: 'Arijit Singh, Mithoon',
            album: 'Aashiqui 2',
            duration: Duration(seconds: 262),
            audioUrl: 'https://example.com/tum2.mp3',
            coverUrl: '',
            releaseYear: '2013',
          ),
          const Song(
            id: 'id_variant_2',
            title: 'Tum Hi Ho [Remastered]',
            artist: 'Arijit Singh',
            album: 'Aashiqui 2',
            duration: Duration(seconds: 262),
            audioUrl: 'https://example.com/tum3.mp3',
            coverUrl: '',
            releaseYear: '2013',
          ),
          const Song(
            id: 'channa_mereya',
            title: 'Channa Mereya',
            artist: 'Arijit Singh',
            album: 'Ae Dil Hai Mushkil',
            duration: Duration(seconds: 289),
            audioUrl: 'https://example.com/channa.mp3',
            coverUrl: '',
            releaseYear: '2016',
          ),
          const Song(
            id: 'channa_mereya_variant',
            title: 'Channa Mereya (From "Ae Dil Hai Mushkil")',
            artist: 'Arijit Singh, Pritam',
            album: 'Ae Dil Hai Mushkil',
            duration: Duration(seconds: 289),
            audioUrl: 'https://example.com/channa2.mp3',
            coverUrl: '',
            releaseYear: '2016',
          ),
        ];

        final queue = await engine.buildSmartQueue(
          seedSong: seed,
          existingQueue: duplicateVariants,
          targetSize: 10,
        );

        // Verify that NO duplicate versions exist in queue
        final seenKeys = <String>{};
        for (final s in queue) {
          final key = SongParserUtils.songDeduplicationKey(s);
          expect(
            seenKeys.contains(key),
            isFalse,
            reason: 'Song "$key" appeared more than once in smart queue!',
          );
          seenKeys.add(key);
        }
      },
    );
  });
}
