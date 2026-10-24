import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/models/playlist.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/recommendation/ai_recommendation_engine.dart';
import 'package:jumbo_music/services/api/music_tag_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiRecommendationEngine Unit Tests', () {
    late AiRecommendationEngine engine;

    final songA = Song(
      id: 'song_a',
      title: 'Kesariya Love',
      artist: 'Arijit Singh, Pritam',
      album: 'Brahmastra',
      audioUrl: 'https://example.com/a.mp3',
      coverUrl: 'https://example.com/a.jpg',
      duration: const Duration(seconds: 240),
    );

    final songB = Song(
      id: 'song_b',
      title: 'Apna Bana Le',
      artist: 'Arijit Singh, Sachin-Jigar',
      album: 'Bhediya',
      audioUrl: 'https://example.com/b.mp3',
      coverUrl: 'https://example.com/b.jpg',
      duration: const Duration(seconds: 210),
    );

    final songParty = Song(
      id: 'song_party',
      title: 'Kala Chashma Party Dance Remix',
      artist: 'Badshah, Neha Kakkar',
      album: 'Baar Baar Dekho',
      audioUrl: 'https://example.com/party.mp3',
      coverUrl: 'https://example.com/party.jpg',
      duration: const Duration(seconds: 190),
    );

    final songSukoon = Song(
      id: 'song_sukoon',
      title: 'Kasoor Lofi Sukoon Acoustic',
      artist: 'Prateek Kuhad',
      album: 'Kasoor',
      audioUrl: 'https://example.com/sukoon.mp3',
      coverUrl: 'https://example.com/sukoon.jpg',
      duration: const Duration(seconds: 200),
    );

    setUp(() async {
      engine = AiRecommendationEngine.instance;
      engine.resetForTesting();
      await DatabaseService.instance.switchUserScope('test_engine_user');
      await DatabaseService.instance.clearHistory();
    });

    test(
      'Pillar 1 - Collaborative Filtering: recordTransition increases score',
      () {
        final initialScore = engine.calculateCollaborativeScore(songA, songB);

        engine.recordTransition(songA.id, songB.id);
        engine.recordTransition(songA.id, songB.id);

        final boostedScore = engine.calculateCollaborativeScore(songA, songB);
        expect(boostedScore, greaterThan(initialScore));
      },
    );

    test(
      'Pillar 1 - Collaborative Filtering: playlist co-occurrence increases score',
      () async {
        final playlist = Playlist(
          id: 'pl_collab',
          title: 'Romantic Duo',
          description: 'Test playlist',
          coverUrl: '',
          songIds: [songA.id, songB.id],
          songs: [songA, songB],
          type: PlaylistType.custom,
        );
        await DatabaseService.instance.addCustomPlaylist(playlist);

        final score = engine.calculateCollaborativeScore(songA, songB);
        expect(score, greaterThanOrEqualTo(0.40));
      },
    );

    test('Pillar 2 - Content-Based Filtering: Tempo and Mood detection', () {
      expect(engine.estimateTempo(songParty), SongTempoCategory.upbeat);
      expect(engine.estimateTempo(songSukoon), SongTempoCategory.slow);
      expect(engine.estimateTempo(songA), SongTempoCategory.midTempo);

      expect(engine.classifyMood(songParty), SongMoodCategory.energetic);
      expect(engine.classifyMood(songSukoon), SongMoodCategory.calmSukoon);
      expect(engine.classifyMood(songA), SongMoodCategory.romantic);
    });

    test(
      'Pillar 2 - Content-Based Filtering: Similar artists and genre score higher',
      () {
        final scoreSimilar = engine.calculateContentScore(songA, songB);
        final scoreDissimilar = engine.calculateContentScore(songA, songParty);

        expect(scoreSimilar, greaterThan(scoreDissimilar));
      },
    );

    test(
      'Pillar 3 - Behavioral Signals: Skip penalty reduces candidate score',
      () {
        final initialScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );

        engine.recordSkip(songB.id);
        final oneSkipScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        expect(oneSkipScore, lessThan(initialScore));

        engine.recordSkip(songB.id);
        final twoSkipsScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        expect(twoSkipsScore, lessThan(oneSkipScore));

        engine.recordSkip(songB.id); // 3 skips -> suppress
        final threeSkipsScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        expect(threeSkipsScore, equals(-1.0));
        expect(engine.scoreCandidate(songA, songB), equals(-100.0));
      },
    );

    test(
      'Pillar 3 - Behavioral Signals: Search history match boosts candidate',
      () async {
        await DatabaseService.instance.addSearchQuery('Bhediya');

        final score = engine.calculateContextualAndBehavioralScore(songB);
        expect(score, greaterThan(0.0));
      },
    );

    test(
      'Pillar 3 - Contextual Modulation: Late-night favors calm/sukoon/slow songs',
      () {
        engine.nowProvider = () => DateTime(2026, 10, 13, 23, 30);

        final sukoonScore = engine.calculateContextualAndBehavioralScore(
          songSukoon,
        );
        final partyScore = engine.calculateContextualAndBehavioralScore(
          songParty,
        );

        expect(sukoonScore, greaterThan(partyScore));
      },
    );

    test(
      'Pillar 3 - The 30-Second Rule: recordCompletedListen increases candidate score',
      () {
        final initialScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        engine.recordCompletedListen(songB.id);
        final completedScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );

        expect(completedScore, greaterThan(initialScore));
      },
    );

    test(
      'Pillar 3 - Spotify Loop Affinity: recordLoop increases candidate score strongly',
      () {
        final initialScore = engine.calculateContextualAndBehavioralScore(
          songB,
        );
        engine.recordLoop(songB.id);
        final loopScore = engine.calculateContextualAndBehavioralScore(songB);

        expect(loopScore, greaterThan(initialScore));
        expect(loopScore - initialScore, closeTo(0.25, 0.01));
      },
    );

    test(
      'Pillar 3 - Regional Language Priority: preferred languages boost matching candidates',
      () async {
        await DatabaseService.instance.saveSetting('preferred_languages', [
          'Hindi',
        ]);
        final hindiScore = engine.calculateContextualAndBehavioralScore(songA);

        await DatabaseService.instance.saveSetting('preferred_languages', [
          'Tamil',
        ]);
        final nonTamilScore = engine.calculateContextualAndBehavioralScore(
          songA,
        );

        expect(hindiScore, greaterThan(nonTamilScore));
      },
    );

    test('selectBestNextSong chooses highest scoring compatible track', () {
      final best = engine.selectBestNextSong(
        currentSong: songA,
        candidates: [songParty, songB, songSukoon],
      );

      expect(best, isNotNull);
      expect(best!.id, equals(songB.id));
    });

    test(
      'buildSmartQueue builds tailored queue starting with seed track',
      () async {
        final queue = await engine.buildSmartQueue(
          seedSong: songA,
          existingQueue: [songB, songParty],
          targetSize: 10,
        );

        expect(queue.isNotEmpty, isTrue);
        expect(queue.first.id, equals(songA.id));
        expect(queue.any((s) => s.id == songB.id), isTrue);
      },
    );

    test(
      'Strict Language Filtering: Disqualifies candidates from other languages',
      () {
        final songEnglish = Song(
          id: 'song_eng_1',
          title: 'Shape of You English Pop',
          artist: 'Ed Sheeran',
          album: 'Divide',
          language: 'English',
          genre: 'Pop',
          audioUrl: 'https://example.com/eng.mp3',
          coverUrl: '',
          duration: const Duration(seconds: 230),
        );

        final score = engine.scoreCandidate(songA, songEnglish);
        expect(score, equals(-100.0));
      },
    );

    test(
      'Preview and Short Track Exclusion: Disqualifies Apple 30s previews and tracks < 75s',
      () {
        final songPreview = Song(
          id: 'itunes_preview',
          title: 'Kesariya Preview',
          artist: 'Arijit Singh',
          audioUrl:
              'https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/mzaf_123.m4a',
          coverUrl: '',
          duration: const Duration(seconds: 240),
        );

        final songShort = Song(
          id: 'short_track',
          title: 'Kesariya Teaser Promo',
          artist: 'Arijit Singh',
          audioUrl: 'https://example.com/teaser.mp3',
          coverUrl: '',
          duration: const Duration(seconds: 45),
        );

        expect(engine.scoreCandidate(songA, songPreview), equals(-100.0));
        expect(engine.scoreCandidate(songA, songShort), equals(-100.0));
      },
    );

    test(
      'Queue Deduplication: Eliminates duplicate versions of same title in queue',
      () async {
        final songBRemaster = Song(
          id: 'song_b_remaster',
          title: 'Apna Bana Le [Remastered]',
          artist: 'Sachin-Jigar, Arijit Singh',
          album: 'Bhediya Special',
          audioUrl: 'https://example.com/b_remaster.mp3',
          coverUrl: '',
          duration: const Duration(seconds: 210),
        );

        final queue = await engine.buildSmartQueue(
          seedSong: songA,
          existingQueue: [songB, songBRemaster],
          targetSize: 10,
        );

        // Only one version of Apna Bana Le should exist in the queue
        final apnaBanaLeCount = queue
            .where((s) => s.title.toLowerCase().contains('apna bana le'))
            .length;
        expect(apnaBanaLeCount, equals(1));
      },
    );

    test(
      'Strict Era Filtering: Disqualifies cross-era candidates with -100.0 score',
      () {
        const vintageSeed = Song(
          id: 'v_seed',
          title: 'Pal Pal Dil Ke Paas',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/vintage.mp3',
          coverUrl: '',
          releaseYear: '1973',
        );

        const ninetiesTrack = Song(
          id: 'n_cand',
          title: 'Tujhe Dekha To',
          artist: 'Kumar Sanu, Alka Yagnik',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/90s.mp3',
          coverUrl: '',
          releaseYear: '1995',
        );

        const twoThousandsTrack = Song(
          id: '2k_cand',
          title: 'Zara Sa',
          artist: 'KK',
          duration: Duration(seconds: 280),
          audioUrl: 'https://example.com/2000s.mp3',
          coverUrl: '',
          releaseYear: '2008',
        );

        const genZTrack = Song(
          id: 'gz_cand',
          title: 'Winning Speech',
          artist: 'Karan Aujla',
          duration: Duration(seconds: 190),
          audioUrl: 'https://example.com/genz.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        const vintageCandidate = Song(
          id: 'v_cand',
          title: 'Gulabi Aankhen',
          artist: 'Mohammed Rafi',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/rafi.mp3',
          coverUrl: '',
          releaseYear: '1970',
        );

        // Cross-era candidates must be strictly disqualified (-100.0)
        expect(
          engine.scoreCandidate(vintageSeed, ninetiesTrack),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(vintageSeed, twoThousandsTrack),
          equals(-100.0),
        );
        expect(engine.scoreCandidate(vintageSeed, genZTrack), equals(-100.0));

        // Same-era candidate must be admitted with positive score
        expect(
          engine.scoreCandidate(vintageSeed, vintageCandidate),
          greaterThan(0.0),
        );
      },
    );

    test(
      'buildSmartQueue Era Consistency: 70s seed queue contains strictly 70s vintage tracks',
      () async {
        const vintageSeed = Song(
          id: 'v_seed',
          title: 'Pal Pal Dil Ke Paas',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/vintage.mp3',
          coverUrl: '',
          releaseYear: '1973',
        );

        const vintageCandidate = Song(
          id: 'v_cand',
          title: 'Gulabi Aankhen',
          artist: 'Mohammed Rafi',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/rafi.mp3',
          coverUrl: '',
          releaseYear: '1970',
        );

        const ninetiesTrack = Song(
          id: 'n_cand',
          title: 'Tujhe Dekha To',
          artist: 'Kumar Sanu, Alka Yagnik',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/90s.mp3',
          coverUrl: '',
          releaseYear: '1995',
        );

        const genZTrack = Song(
          id: 'gz_cand',
          title: 'Winning Speech',
          artist: 'Karan Aujla',
          duration: Duration(seconds: 190),
          audioUrl: 'https://example.com/genz.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        final queue = await engine.buildSmartQueue(
          seedSong: vintageSeed,
          existingQueue: [vintageCandidate, ninetiesTrack, genZTrack],
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == vintageSeed.id), isTrue);
        expect(queue.any((s) => s.id == vintageCandidate.id), isTrue);
        expect(queue.any((s) => s.id == ninetiesTrack.id), isFalse);
        expect(queue.any((s) => s.id == genZTrack.id), isFalse);
      },
    );

    test('Delimited Title Duplicate Prevention in buildSmartQueue', () async {
      const vintageSeed = Song(
        id: 'v_seed',
        title: 'Pal Pal Dil Ke Paas',
        artist: 'Kishore Kumar',
        duration: Duration(seconds: 300),
        audioUrl: 'https://example.com/vintage.mp3',
        coverUrl: '',
        releaseYear: '1973',
      );

      const upload1 = Song(
        id: 's_upload1',
        title: 'Pal Pal Dil Ke Paas - Kishore Kumar',
        artist: 'Kishore Kumar',
        duration: Duration(seconds: 300),
        audioUrl: 'https://example.com/u1.mp3',
        coverUrl: '',
        releaseYear: '1973',
      );

      const upload2 = Song(
        id: 's_upload2',
        title: 'Pal Pal Dil Ke Paas (From "Blackmail")',
        artist: 'Kalyanji Anandji',
        duration: Duration(seconds: 300),
        audioUrl: 'https://example.com/u2.mp3',
        coverUrl: '',
        releaseYear: '1973',
      );

      const upload3 = Song(
        id: 's_upload3',
        title: 'Pal Pal Dil Ke Paas | Remastered',
        artist: 'Kishore Kumar',
        duration: Duration(seconds: 300),
        audioUrl: 'https://example.com/u3.mp3',
        coverUrl: '',
        releaseYear: '1973',
      );

      final queue = await engine.buildSmartQueue(
        seedSong: vintageSeed,
        existingQueue: [upload1, upload2, upload3],
        targetSize: 10,
      );

      // Queue must contain only the seed song, 0 duplicate uploads
      expect(queue.length, equals(1));
      expect(queue.first.id, equals(vintageSeed.id));
    });

    test(
      'Compilation Album Era Invariance: Kishore Kumar/Rafi with 2021 releaseYear stay strictly Vintage 70s',
      () async {
        const kishoreCompilation = Song(
          id: 'kishore_2021',
          title: 'Mere Sapno Ki Rani',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 290),
          audioUrl: 'https://example.com/kishore.mp3',
          coverUrl: '',
          releaseYear: '2021', // Modern compilation date from streaming API
        );

        const rafiCompilation = Song(
          id: 'rafi_2023',
          title: 'Gulabi Aankhen',
          artist: 'Mohammed Rafi',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/rafi.mp3',
          coverUrl: '',
          releaseYear: '2023', // Modern compilation date
        );

        const sanuCompilation = Song(
          id: 'sanu_2022',
          title: 'Chura Ke Dil Mera',
          artist: 'Kumar Sanu, Alka Yagnik',
          duration: Duration(seconds: 280),
          audioUrl: 'https://example.com/sanu.mp3',
          coverUrl: '',
          releaseYear: '2022',
        );

        const kkCompilation = Song(
          id: 'kk_2024',
          title: 'Zara Sa',
          artist: 'KK',
          duration: Duration(seconds: 270),
          audioUrl: 'https://example.com/kk.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        const genZTrack = Song(
          id: 'genz_2024',
          title: 'Tauba Tauba',
          artist: 'Karan Aujla',
          duration: Duration(seconds: 190),
          audioUrl: 'https://example.com/genz.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        expect(
          MusicTagClassifier.detectSongEra(kishoreCompilation),
          equals(MusicEra.vintage70s),
        );
        expect(
          MusicTagClassifier.detectSongEra(rafiCompilation),
          equals(MusicEra.vintage70s),
        );
        expect(
          MusicTagClassifier.detectSongEra(sanuCompilation),
          equals(MusicEra.era90s),
        );
        expect(
          MusicTagClassifier.detectSongEra(kkCompilation),
          equals(MusicEra.era2000s),
        );
        expect(
          MusicTagClassifier.detectSongEra(genZTrack),
          equals(MusicEra.genZModern),
        );

        // Kishore seed must admit Rafi compilation, and reject Sanu (90s), KK (2000s), and Gen Z
        expect(
          engine.scoreCandidate(kishoreCompilation, rafiCompilation),
          greaterThan(0.0),
        );
        expect(
          engine.scoreCandidate(kishoreCompilation, sanuCompilation),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(kishoreCompilation, kkCompilation),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(kishoreCompilation, genZTrack),
          equals(-100.0),
        );
      },
    );

    test(
      'Strict English vs Hindi Isolation: English songs never leak into Hindi queue and vice versa',
      () async {
        const hindiSeed = Song(
          id: 'h_seed',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          duration: Duration(seconds: 260),
          audioUrl: 'https://example.com/tumhiho.mp3',
          coverUrl: '',
          releaseYear: '2013',
        );

        const englishTrackStay = Song(
          id: 'e_stay',
          title: 'Stay',
          artist: 'The Kid LAROI, Justin Bieber',
          duration: Duration(seconds: 140),
          audioUrl: 'https://example.com/stay.mp3',
          coverUrl: '',
          releaseYear: '2021',
        );

        const englishTrackStarboy = Song(
          id: 'e_starboy',
          title: 'Starboy',
          artist: 'The Weeknd',
          duration: Duration(seconds: 230),
          audioUrl: 'https://example.com/starboy.mp3',
          coverUrl: '',
          releaseYear: '2016',
        );

        const jamendoEnglish = Song(
          id: 'jamendo_99182',
          title: 'Acoustic Morning Breeze',
          artist: 'Western Indie Band',
          duration: Duration(seconds: 210),
          audioUrl: 'https://prod-1.storage.jamendo.com/track.mp3',
          coverUrl: '',
          releaseYear: '2023',
        );

        const hindiCompatible = Song(
          id: 'h_comp',
          title: 'Sunn Raha Hai Na Tu',
          artist: 'Ankit Tiwari',
          album: 'Aashiqui 2',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/sunnraha.mp3',
          coverUrl: '',
          releaseYear: '2013',
        );

        // Language detection verification
        expect(
          MusicTagClassifier.detectSongLanguage(hindiSeed),
          equals('Hindi'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(englishTrackStay),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(englishTrackStarboy),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(jamendoEnglish),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(hindiCompatible),
          equals('Hindi'),
        );

        // All English songs must be strictly rejected (-100.0) from Hindi seed
        expect(
          engine.scoreCandidate(hindiSeed, englishTrackStay),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(hindiSeed, englishTrackStarboy),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(hindiSeed, jamendoEnglish),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(hindiSeed, hindiCompatible),
          greaterThan(0.0),
        );

        // In smart queue, none of the English tracks can enter the Hindi queue
        final queue = await engine.buildSmartQueue(
          seedSong: hindiSeed,
          existingQueue: [
            englishTrackStay,
            englishTrackStarboy,
            jamendoEnglish,
            hindiCompatible,
          ],
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == englishTrackStay.id), isFalse);
        expect(queue.any((s) => s.id == englishTrackStarboy.id), isFalse);
        expect(queue.any((s) => s.id == jamendoEnglish.id), isFalse);
        expect(queue.any((s) => s.id == hindiCompatible.id), isTrue);

        // Reverse check: In English seed queue, Hindi songs must be rejected
        expect(
          engine.scoreCandidate(englishTrackStarboy, hindiSeed),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(englishTrackStarboy, hindiCompatible),
          equals(-100.0),
        );
      },
    );

    test(
      'Darshan Raval - Hawa Banke: Zero English pollution and zero history leakage',
      () async {
        const darshanHawaBanke = Song(
          id: 'dr_hawa_banke',
          title: 'Hawa Banke',
          artist: 'Darshan Raval',
          album: 'Single',
          duration: Duration(seconds: 195),
          audioUrl: 'https://example.com/hawabanke.mp3',
          coverUrl: '',
          releaseYear: '2020',
        );

        const darshanAsalMein = Song(
          id: 'dr_asal_mein',
          title: 'Asal Mein',
          artist: 'Darshan Raval',
          album: 'Single',
          duration: Duration(seconds: 220),
          audioUrl: 'https://example.com/asalmein.mp3',
          coverUrl: '',
          releaseYear: '2020',
        );

        const englishTeddySwims = Song(
          id: 'e_teddy_swims',
          title: 'Lose Control',
          artist: 'Teddy Swims',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/losecontrol.mp3',
          coverUrl: '',
          releaseYear: '2023',
        );

        const englishSabrina = Song(
          id: 'e_sabrina',
          title: 'Taste',
          artist: 'Sabrina Carpenter',
          duration: Duration(seconds: 160),
          audioUrl: 'https://example.com/taste.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        const englishMarkAmbor = Song(
          id: 'e_mark_ambor',
          title: 'Belong Together',
          artist: 'Mark Ambor',
          duration: Duration(seconds: 145),
          audioUrl: 'https://example.com/belongtogether.mp3',
          coverUrl: '',
          releaseYear: '2024',
        );

        const anuvOcean = Song(
          id: 'anuv_ocean',
          title: 'Ocean',
          artist: 'Anuv Jain',
          duration: Duration(seconds: 200),
          audioUrl: 'https://example.com/ocean.mp3',
          coverUrl: '',
          releaseYear: '2018',
        );

        const anuvBaarishein = Song(
          id: 'anuv_baarishein',
          title: 'Baarishein',
          artist: 'Anuv Jain',
          duration: Duration(seconds: 210),
          audioUrl: 'https://example.com/baarishein.mp3',
          coverUrl: '',
          releaseYear: '2018',
        );

        const oldHistorySongKishore = Song(
          id: 'hist_kishore',
          title: 'Pal Pal Dil Ke Paas',
          artist: 'Kishore Kumar',
          duration: Duration(seconds: 300),
          audioUrl: 'https://example.com/palpal.mp3',
          coverUrl: '',
          releaseYear: '1973',
        );

        // 1. Language detection assertions
        expect(
          MusicTagClassifier.detectSongLanguage(darshanHawaBanke),
          equals('Hindi'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(englishTeddySwims),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(englishSabrina),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(englishMarkAmbor),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(anuvOcean),
          equals('English'),
        );
        expect(
          MusicTagClassifier.detectSongLanguage(anuvBaarishein),
          equals('Hindi'),
        );

        // 2. Era isolation
        expect(
          MusicTagClassifier.detectSongEra(darshanHawaBanke),
          equals(MusicEra.genZModern),
        );
        expect(
          MusicTagClassifier.detectSongEra(oldHistorySongKishore),
          equals(MusicEra.vintage70s),
        );

        // 3. Score candidate checks: English and old vintage tracks must score -100.0
        expect(
          engine.scoreCandidate(darshanHawaBanke, englishTeddySwims),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(darshanHawaBanke, englishSabrina),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(darshanHawaBanke, englishMarkAmbor),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(darshanHawaBanke, anuvOcean),
          equals(-100.0),
        );
        expect(
          engine.scoreCandidate(darshanHawaBanke, oldHistorySongKishore),
          equals(-100.0),
        );

        // Same artist / compatible Hindi modern track must score > 0
        expect(
          engine.scoreCandidate(darshanHawaBanke, darshanAsalMein),
          greaterThan(0.0),
        );

        // 4. Smart queue generation: Verify English and History tracks are completely excluded
        final queue = await engine.buildSmartQueue(
          seedSong: darshanHawaBanke,
          existingQueue: [
            englishTeddySwims,
            englishSabrina,
            englishMarkAmbor,
            anuvOcean,
            oldHistorySongKishore,
            darshanAsalMein,
          ],
          targetSize: 10,
        );

        expect(queue.any((s) => s.id == englishTeddySwims.id), isFalse);
        expect(queue.any((s) => s.id == englishSabrina.id), isFalse);
        expect(queue.any((s) => s.id == englishMarkAmbor.id), isFalse);
        expect(queue.any((s) => s.id == anuvOcean.id), isFalse);
        expect(queue.any((s) => s.id == oldHistorySongKishore.id), isFalse);
        expect(queue.any((s) => s.id == darshanAsalMein.id), isTrue);
      },
    );
  });
}
