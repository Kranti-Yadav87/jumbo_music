import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/song.dart';
import '../crash_reporting_service.dart';

/// Legal full-length catalog: Jamendo (Creative Commons / independent music).
///
/// Unlike the 30-second iTunes preview fallback, Jamendo returns the FULL
/// track for streaming. It needs a free client id
/// (https://devportal.jamendo.com) passed as
/// `--dart-define=JAMENDO_CLIENT_ID=xxxx`. Without it this service is a no-op.
///
/// Licensing note: Jamendo's free API tier is for non-commercial use. If the
/// app is ever monetised, use Jamendo's commercial licensing or another
/// licensed provider.
class JamendoSearchService {
  JamendoSearchService._();

  static bool get isConfigured => AppConfig.jamendoClientId.isNotEmpty;

  static Future<List<Song>> search(String query, {int limit = 25}) async {
    if (!isConfigured || query.trim().isEmpty) return [];
    try {
      final uri = Uri.https('api.jamendo.com', '/v3.0/tracks/', {
        'client_id': AppConfig.jamendoClientId,
        'format': 'json',
        'limit': '$limit',
        'search': query.trim(),
        'audioformat': 'mp32',
        'include': 'musicinfo',
        'imagesize': '600',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return [];
      return parseTracks(data);
    } catch (error) {
      CrashReportingService.swallow(
        error,
        'jamendo_search_service.dart:search',
      );
      return [];
    }
  }

  /// Pure parser (unit-tested): converts a Jamendo `/tracks` response to songs.
  static List<Song> parseTracks(Map<String, dynamic> data) {
    final results = data['results'];
    if (results is! List) return [];
    final songs = <Song>[];
    for (final item in results) {
      if (item is! Map) continue;
      final id = item['id']?.toString();
      final name = item['name']?.toString();
      final artist = item['artist_name']?.toString();
      final audio = item['audio']?.toString();
      if (id == null ||
          id.isEmpty ||
          name == null ||
          name.isEmpty ||
          artist == null ||
          artist.isEmpty ||
          audio == null ||
          audio.isEmpty) {
        continue;
      }
      final seconds = item['duration'] is num
          ? (item['duration'] as num).toInt()
          : int.tryParse('${item['duration']}') ?? 0;
      final release = item['releasedate']?.toString() ?? '';
      final year = release.length >= 4 ? release.substring(0, 4) : '';
      final album = item['album_name']?.toString();
      songs.add(
        Song(
          id: 'jamendo_$id',
          title: name,
          artist: artist,
          album: (album == null || album.isEmpty) ? 'Single' : album,
          duration: Duration(seconds: seconds),
          audioUrl: audio,
          coverUrl: item['image']?.toString() ?? '',
          genre: _firstGenre(item['musicinfo']),
          language: 'English',
          releaseYear: year.isEmpty ? '2026' : year,
          quality: 'MP3 (full track)',
        ),
      );
    }
    return songs;
  }

  static String _firstGenre(dynamic musicinfo) {
    if (musicinfo is Map) {
      final tags = musicinfo['tags'];
      if (tags is Map && tags['genres'] is List) {
        final genres = tags['genres'] as List;
        if (genres.isNotEmpty) return genres.first.toString();
      }
    }
    return 'Music';
  }
}
