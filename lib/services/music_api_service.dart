import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicApiService {
  static const String _endpoint =
      'https://uwvsyladvvvjqlgnqppq.supabase.co/functions/v1/spotify';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3dnN5bGFkdnZ2anFsZ25xcHBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNDY3NDEsImV4cCI6MjA4NzgyMjc0MX0.ibwH6IntJjky3uZKxFplDkVGW9bSH0RrwT0cVrd94hI';

  static Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      };

  static String _unescape(String? input) {
    if (input == null) return '';
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#38;', '&')
        .replaceAll('&#34;', '"')
        .trim();
  }

  static String _extractImage(dynamic imageObj) {
    if (imageObj == null) return '';
    if (imageObj is String) return imageObj;
    if (imageObj is List && imageObj.isNotEmpty) {
      // Pick highest quality (500x500 is usually at the end)
      final last = imageObj.last;
      if (last is Map) {
        return (last['url'] as String?) ?? (last['link'] as String?) ?? '';
      }
    }
    return '';
  }

  static String _extractAudioUrl(dynamic downloadUrlObj) {
    if (downloadUrlObj == null) return '';
    if (downloadUrlObj is String) return downloadUrlObj;
    if (downloadUrlObj is List && downloadUrlObj.isNotEmpty) {
      // Index 4 is 320kbps, index 3 is 160kbps
      for (final item in downloadUrlObj.reversed) {
        if (item is Map) {
          final url = (item['url'] as String?) ?? (item['link'] as String?);
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
    }
    return '';
  }

  static String _extractArtists(dynamic item) {
    if (item == null) return 'Unknown Artist';
    if (item['artists'] != null && item['artists']['primary'] != null) {
      final primaries = item['artists']['primary'];
      if (primaries is List) {
        final names = primaries.map((a) => a['name'] as String? ?? '').where((n) => n.isNotEmpty).toList();
        if (names.isNotEmpty) return _unescape(names.join(', '));
      }
    }
    if (item['primaryArtists'] != null && item['primaryArtists'] is String) {
      return _unescape(item['primaryArtists']);
    }
    if (item['subtitle'] != null && item['subtitle'] is String) {
      final sub = item['subtitle'] as String;
      return _unescape(sub.split(' - ').first);
    }
    return 'Unknown Artist';
  }

  static Song? _parseSong(Map<String, dynamic> item) {
    try {
      final audioUrl = _extractAudioUrl(item['downloadUrl']);
      final name = _unescape(item['name'] ?? item['song'] ?? item['title']);
      if (audioUrl.isEmpty || name.isEmpty) return null;

      final artist = _extractArtists(item);
      final rawAlbum = item['album'];
      final album = rawAlbum is Map
          ? _unescape(rawAlbum['name'] as String?)
          : _unescape(rawAlbum as String? ?? 'Single');

      final coverUrl = _extractImage(item['image']);
      final id = (item['id'] as String?) ??
          'song_${DateTime.now().millisecondsSinceEpoch}';

      final durationSec = int.tryParse(item['duration']?.toString() ?? '0') ?? 240;
      final year = item['year']?.toString() ?? '2025';

      return Song(
        id: id,
        title: name,
        artist: artist,
        album: album.isNotEmpty ? album : 'Single',
        duration: Duration(seconds: durationSec),
        audioUrl: audioUrl,
        coverUrl: coverUrl.isNotEmpty
            ? coverUrl
            : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
        genre: 'Hindi & Bollywood',
        releaseYear: year,
        quality: '320 kbps Studio HD',
        isLiveStream: true,
        lyrics: '''
[Live Streamed via Aura/JioSaavn Engine]
Title: $name
Artist: $artist
Album: $album
Audio Stream: 320 kbps Original Master

🎵 Playing live high-quality uninterrupted stream with Jumbo Music!
''',
      );
    } catch (_) {
      return null;
    }
  }

  /// Live Search matching aura-stream-henna.vercel.app
  static Future<List<Song>> searchLiveSongs(String query, {int limit = 30}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_endpoint?action=jiosaavn-search&q=${Uri.encodeComponent(cleanQuery)}&limit=$limit',
      );

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final innerData = data['data'];

        List<dynamic> results = [];
        if (innerData is Map && innerData['results'] is List) {
          results = innerData['results'] as List<dynamic>;
        } else if (data['results'] is List) {
          results = data['results'] as List<dynamic>;
        }

        final List<Song> songs = [];
        for (final item in results) {
          if (item is Map<String, dynamic>) {
            final song = _parseSong(item);
            if (song != null) {
              songs.add(song);
            }
          }
        }
        if (songs.isNotEmpty) return songs;
      }
    } catch (_) {
      // Fallback below
    }

    // Fallback: iTunes live search
    return searchOnlineSongsFallback(cleanQuery, limit: limit);
  }

  /// Fetch playlist songs by ID
  static Future<Map<String, dynamic>> fetchPlaylist(String playlistId) async {
    try {
      final uri = Uri.parse(
        '$_endpoint?action=jiosaavn-playlist&id=$playlistId',
      );

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = response.body;
        final data = jsonDecode(body) as Map<String, dynamic>;
        final pData = data['data'] as Map<String, dynamic>? ?? {};

        final name = _unescape(pData['name'] ?? pData['title'] ?? 'Playlist');
        final coverUrl = _extractImage(pData['image']);
        final songList = pData['songs'] ?? pData['list'] ?? [];

        final List<Song> songs = [];
        if (songList is List) {
          for (final item in songList) {
            if (item is Map<String, dynamic>) {
              final song = _parseSong(item);
              if (song != null) songs.add(song);
            }
          }
        }

        return {
          'id': playlistId,
          'name': name,
          'coverUrl': coverUrl,
          'songs': songs,
        };
      }
    } catch (_) {}
    return {'id': playlistId, 'name': 'Playlist', 'coverUrl': '', 'songs': <Song>[]};
  }

  /// Curated featured playlists identical to Aura Stream
  static Future<List<Song>> fetchIndiaTop50() async {
    final result = await fetchPlaylist('1134543272');
    return (result['songs'] as List<Song>?) ?? [];
  }

  static Future<List<Song>> fetchTrendingToday() async {
    final result = await fetchPlaylist('110858205');
    return (result['songs'] as List<Song>?) ?? [];
  }

  static Future<List<Song>> fetchBestOfIndie() async {
    final result = await fetchPlaylist('82914609');
    return (result['songs'] as List<Song>?) ?? [];
  }

  static Future<List<Song>> fetch90sDuets() async {
    final result = await fetchPlaylist('159470188');
    return (result['songs'] as List<Song>?) ?? [];
  }

  /// iTunes fallback
  static Future<List<Song>> searchOnlineSongsFallback(String query, {int limit = 25}) async {
    try {
      final uri = Uri.https('itunes.apple.com', '/search', {
        'term': query.trim(),
        'media': 'music',
        'entity': 'song',
        'limit': '$limit',
      });

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

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
          final trackId = item['trackId']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();
          final releaseDate = (item['releaseDate'] as String?) ?? '';
          final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '2025';
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
                  : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
              genre: genre,
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

  /// Discovers 50+ related, diverse songs matching the seed song's artist,
  /// style and mood for endless "Continue Playing - Autoplaying similar music".
  static Future<List<Song>> fetchSmartRecommendations(Song seedSong, {int limit = 50}) async {
    final List<Song> recommendations = [];
    final Set<String> seenIds = {seedSong.id};
    final Set<String> seenTitles = {seedSong.title.toLowerCase().trim()};

    // 1. Direct Artist Match: Fetch top tracks from the seed song's artist
    final rawArtist = seedSong.artist
        .split(',')
        .first
        .split('&')
        .first
        .split('feat.')
        .first
        .trim();
    if (rawArtist.isNotEmpty &&
        rawArtist.toLowerCase() != 'unknown artist' &&
        rawArtist.toLowerCase() != 'music') {
      try {
        final artistSongs = await searchLiveSongs(rawArtist, limit: 20);
        for (final song in artistSongs) {
          final lowerTitle = song.title.toLowerCase().trim();
          if (!seenIds.contains(song.id) &&
              !seenTitles.contains(lowerTitle) &&
              !lowerTitle.contains(seedSong.title.toLowerCase()) &&
              song.audioUrl.isNotEmpty) {
            seenIds.add(song.id);
            seenTitles.add(lowerTitle);
            recommendations.add(song);
            if (recommendations.length >= limit) return recommendations;
          }
        }
      } catch (_) {}
    }

    // 2. Contextual Mood & Related Discovery Queries
    final List<String> discoveryQueries = [];
    final artistLower = seedSong.artist.toLowerCase();
    final genreLower = seedSong.genre.toLowerCase();

    if (artistLower.contains('quratulain') ||
        artistLower.contains('balouch') ||
        artistLower.contains('kaifi') ||
        artistLower.contains('afusic') ||
        artistLower.contains('kushagra') ||
        artistLower.contains('faheem') ||
        artistLower.contains('bhoomi') ||
        artistLower.contains('sufi') ||
        genreLower.contains('indie') ||
        genreLower.contains('acoustic') ||
        genreLower.contains('romantic') ||
        genreLower.contains('bollywood') ||
        artistLower.contains('arijit') ||
        artistLower.contains('sukoon')) {
      discoveryQueries.addAll([
        'Jaane Na Tu',
        'Sitaare Arijit',
        'Pal Pal Afusic',
        'Ishq Faheem Abdullah',
        'Pyar Se Kushagra',
        'Starstruck UR DEBUT',
        'Kahani Suno Kaifi',
        'Suniyan Suniyan Juss',
        'Ve Haaniyaan',
        'Mohit Chauhan Hits',
        'Atif Aslam Sukoon',
        'Shreya Ghoshal Hits',
        'KK Hindi Hits',
        'Arijit Singh Romantic',
        'Jubin Nautiyal Sukoon',
        'Coke Studio Hits',
      ]);
    } else if (artistLower.contains('diljit') ||
        artistLower.contains('sidhu') ||
        artistLower.contains('karan') ||
        artistLower.contains('shubh') ||
        genreLower.contains('punjabi')) {
      discoveryQueries.addAll([
        'Diljit Dosanjh Hits',
        'Karan Aujla New',
        'AP Dhillon Hits',
        'Sidhu Moosewala Hits',
        'Suniyan Suniyan Juss',
        'Ve Haaniyaan',
        'Shubh Punjabi Hits',
        'Amrinder Gill Hits',
      ]);
    } else if (genreLower.contains('lo-fi') || genreLower.contains('chill')) {
      discoveryQueries.addAll([
        'Lo-Fi Hindi Sukoon',
        'Chillhop beats',
        'Midnight Lo-Fi',
        'Anuv Jain Hits',
        'Jasleen Royal Acoustic',
        'Prateek Kuhad Melodies',
      ]);
    } else if (genreLower.contains('edm') || genreLower.contains('dance')) {
      discoveryQueries.addAll([
        'Nucleya Bass',
        'Ritviz Hits',
        'Desi Party Hits',
        'Club Dance Bollywood',
      ]);
    } else {
      discoveryQueries.addAll([
        'Trending Hindi Songs',
        'Top Bollywood Melodies',
        'India Top 50 Hits',
        'Viral Spotify India',
      ]);
    }

    discoveryQueries.shuffle();
    for (final query in discoveryQueries) {
      if (recommendations.length >= limit) break;
      try {
        final results = await searchLiveSongs(query, limit: 12);
        for (final song in results) {
          final lowerTitle = song.title.toLowerCase().trim();
          if (!seenIds.contains(song.id) &&
              !seenTitles.contains(lowerTitle) &&
              !lowerTitle.contains(seedSong.title.toLowerCase()) &&
              song.audioUrl.isNotEmpty) {
            seenIds.add(song.id);
            seenTitles.add(lowerTitle);
            recommendations.add(song);
            if (recommendations.length >= limit) break;
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: Trending Today and Top 50 to ensure full 50-song queue
    if (recommendations.length < limit) {
      try {
        final trending = await fetchTrendingToday();
        for (final song in trending) {
          if (!seenIds.contains(song.id) && song.id != seedSong.id) {
            seenIds.add(song.id);
            recommendations.add(song);
            if (recommendations.length >= limit) break;
          }
        }
      } catch (_) {}
    }

    if (recommendations.length < limit) {
      try {
        final top50 = await fetchIndiaTop50();
        for (final song in top50) {
          if (!seenIds.contains(song.id) && song.id != seedSong.id) {
            seenIds.add(song.id);
            recommendations.add(song);
            if (recommendations.length >= limit) break;
          }
        }
      } catch (_) {}
    }

    return recommendations;
  }
}

