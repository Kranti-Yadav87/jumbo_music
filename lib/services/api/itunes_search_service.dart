import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song.dart';

/// Service for fallback song searches via iTunes Public API.
class ITunesSearchService {
  ITunesSearchService._();

  static Future<List<Song>> searchOnlineSongsFallback(
    String query, {
    int limit = 25,
  }) async {
    try {
      final uri = Uri.https('itunes.apple.com', '/search', {
        'term': query.trim(),
        'media': 'music',
        'entity': 'song',
        'limit': '$limit',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = response.body;
        final data = jsonDecode(body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        final List<Song> songs = [];
        for (final item in results) {
          final previewUrl = item['previewUrl'] as String?;
          final trackName = item['trackName'] as String?;
          final artistName = item['artistName'] as String?;
          if (previewUrl == null || trackName == null || artistName == null) {
            continue;
          }

          final rawCover = (item['artworkUrl100'] as String?) ?? '';
          final hdCover = rawCover.replaceAll('100x100bb', '600x600bb');
          final albumName = (item['collectionName'] as String?) ?? 'Single';
          final genre = (item['primaryGenreName'] as String?) ?? 'Music';
          final trackId =
              item['trackId']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();
          final releaseDate = (item['releaseDate'] as String?) ?? '';
          final year = releaseDate.length >= 4
              ? releaseDate.substring(0, 4)
              : '2025';
          final trackMillis = (item['trackTimeMillis'] as int?) ?? 30000;

          songs.add(
            Song(
              id: 'itunes_$trackId',
              title: trackName,
              artist: artistName,
              album: albumName,
              duration: Duration(milliseconds: trackMillis),
              audioUrl: previewUrl,
              coverUrl: hdCover.isNotEmpty
                  ? hdCover
                  : 'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
              genre: genre,
              language: 'Hindi',
              releaseYear: year,
              quality: '256 kbps AAC HD',
              isLiveStream: true,
              lyrics: '''
[Live Streamed Track]
Title: $trackName
Artist: $artistName
Album: $albumName
Genre: $genre
''',
            ),
          );
        }
        return songs;
      }
    } catch (_) {}
    return [];
  }
}
