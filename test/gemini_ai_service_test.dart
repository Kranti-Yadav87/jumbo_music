import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/config/app_config.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/gemini_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiAiService & AppConfig AI Tests', () {
    test('AppConfig exposes configured geminiApiKey', () {
      expect(AppConfig.geminiApiKey, isNotEmpty);
      expect(AppConfig.geminiApiKey.startsWith('AQ.'), isTrue);
    });

    test('AiSongRecommendation serializes and deserializes correctly', () {
      final json = {
        'title': 'Kesariya',
        'artist': 'Arijit Singh',
        'vibe': 'Soulful Romantic',
      };
      final rec = AiSongRecommendation.fromJson(json);
      expect(rec.title, 'Kesariya');
      expect(rec.artist, 'Arijit Singh');
      expect(rec.vibe, 'Soulful Romantic');
    });

    test('SongAiInsight fallback produces comprehensive insights', () {
      const song = Song(
        id: 'test_song',
        title: 'Baarishein',
        artist: 'Anuv Jain',
        album: 'Acoustic Rain',
        coverUrl: 'https://example.com/cover.jpg',
        audioUrl: 'https://example.com/audio.mp3',
        duration: Duration(seconds: 210),
      );

      final insight = SongAiInsight.fallback(song);
      expect(insight.songTitle, 'Baarishein');
      expect(insight.artist, 'Anuv Jain');
      expect(insight.mood, isNotEmpty);
      expect(insight.energyLevel, isNotEmpty);
      expect(insight.story, contains('Baarishein'));
      expect(insight.listeningContext, isNotEmpty);
      expect(insight.similarArtists, isNotEmpty);
    });

    test('GeminiAiService returns curated recommendations for mood categories', () async {
      final service = GeminiAiService.instance;

      // When API call fails or runs in unit test environment, fallback handles gracefully
      final gymRecs = await service.generateRecommendations(prompt: 'Gym beast workout energy');
      expect(gymRecs, isNotEmpty);
      expect(gymRecs.any((r) => r.title.isNotEmpty), isTrue);

      final rainRecs = await service.generateRecommendations(prompt: 'Rainy chai romantic vibes');
      expect(rainRecs, isNotEmpty);
      expect(rainRecs.any((r) => r.title.isNotEmpty), isTrue);

      final nightRecs = await service.generateRecommendations(prompt: 'Late night highway drive');
      expect(nightRecs, isNotEmpty);
      expect(nightRecs.any((r) => r.title.isNotEmpty), isTrue);
    });

    test('getSongInsights returns insights for song model', () async {
      const song = Song(
        id: 'song_99',
        title: 'Tum Se Hi',
        artist: 'Mohit Chauhan',
        album: 'Jab We Met',
        coverUrl: 'https://example.com/cover.jpg',
        audioUrl: 'https://example.com/audio.mp3',
        duration: Duration(seconds: 320),
      );

      final insight = await GeminiAiService.instance.getSongInsights(song);
      expect(insight.songTitle, 'Tum Se Hi');
      expect(insight.artist, 'Mohit Chauhan');
      expect(insight.mood, isNotEmpty);
      expect(insight.story, isNotEmpty);
    });
  });
}
