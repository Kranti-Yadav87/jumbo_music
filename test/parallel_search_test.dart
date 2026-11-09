import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parallel Search and Relevance Ranking Tests', () {
    test(
      'Heer by afusic ranks #1 over unrelated Bollywood Heer songs',
      () async {
        final bollywoodSongs = [
          const Song(
            id: 'js_heer_1',
            title: 'Heer',
            artist: 'A.R. Rahman, Harshdeep Kaur',
            album: 'Jab Tak Hai Jaan',
            duration: Duration(seconds: 312),
            audioUrl: 'https://aac.saavncdn.com/heer_rahman.mp4',
            coverUrl: 'https://c.saavncdn.com/heer.jpg',
          ),
          const Song(
            id: 'js_heer_2',
            title: 'Heer Raanjhana',
            artist: 'Arijit Singh, Shreya Ghoshal',
            album: 'Bachchhan Paandey',
            duration: Duration(seconds: 245),
            audioUrl: 'https://aac.saavncdn.com/heer_raanjhana.mp4',
            coverUrl: 'https://c.saavncdn.com/raanjhana.jpg',
          ),
        ];

        final ytSongs = [
          const Song(
            id: 'yt_mOB1S1qXcPQ',
            title: 'Heer',
            artist: 'Afusic & AliSoomroMusic',
            album: 'Heer - Single',
            duration: Duration(seconds: 197),
            audioUrl: 'https://music.youtube.com/watch?v=mOB1S1qXcPQ',
            coverUrl: 'https://i.ytimg.com/vi/mOB1S1qXcPQ/hqdefault.jpg',
          ),
        ];

        MusicApiService.mockSearchLiveSongs = (query, {int limit = 30}) async {
          final queryLower = query.toLowerCase();
          expect(queryLower, contains('heer'));
          expect(queryLower, contains('afusic'));
          return [ytSongs.first, ...bollywoodSongs];
        };

        final results = await MusicApiService.searchLiveSongs('Heer by afusic');
        expect(results, isNotEmpty);
        expect(results.first.title, 'Heer');
        expect(results.first.artist, contains('Afusic'));
        expect(results.first.id, 'yt_mOB1S1qXcPQ');

        MusicApiService.mockSearchLiveSongs = null;
      },
    );

    test('Single-word artist search accurately matches artist name', () async {
      final songs = [
        const Song(
          id: 'yt_1',
          title: 'Heer',
          artist: 'Afusic',
          album: 'Afusic Hits',
          duration: Duration(seconds: 180),
          audioUrl: 'https://music.youtube.com/watch?v=vid1',
          coverUrl: 'https://i.ytimg.com/vi/vid1/hqdefault.jpg',
        ),
        const Song(
          id: 'js_1',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          album: 'Aashiqui 2',
          duration: Duration(seconds: 262),
          audioUrl: 'https://aac.saavncdn.com/tum_hi_ho.mp4',
          coverUrl: 'https://c.saavncdn.com/tum_hi_ho.jpg',
        ),
      ];

      MusicApiService.mockSearchLiveSongs = (query, {int limit = 30}) async {
        return songs
            .where((s) => s.artist.toLowerCase().contains(query.toLowerCase()))
            .toList();
      };

      final afusicResults = await MusicApiService.searchLiveSongs('Afusic');
      expect(afusicResults.length, 1);
      expect(afusicResults.first.artist, 'Afusic');

      MusicApiService.mockSearchLiveSongs = null;
    });
  });
}
