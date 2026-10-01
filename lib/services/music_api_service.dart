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

  /// Checks if a song belongs to the 50s-70s Golden Era, 80s Retro, or 90s Melodies
  static bool isOldClassicSong(Song song) {
    final artistLower = song.artist.toLowerCase();
    final genreLower = song.genre.toLowerCase();
    final titleLower = song.title.toLowerCase();

    // Release Year Check
    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 1940 && year < 2000) {
      return true;
    }

    return artistLower.contains('asha bhosle') ||
        artistLower.contains('lata mangeshkar') ||
        artistLower.contains('kishore kumar') ||
        artistLower.contains('mohammed rafi') ||
        artistLower.contains('mohd rafi') ||
        artistLower.contains('rafi') ||
        artistLower.contains('mukesh') ||
        artistLower.contains('r. d. burman') ||
        artistLower.contains('rd burman') ||
        artistLower.contains('s. d. burman') ||
        artistLower.contains('sd burman') ||
        artistLower.contains('hemant kumar') ||
        artistLower.contains('talat mahmood') ||
        artistLower.contains('manna dey') ||
        artistLower.contains('geeta dutt') ||
        artistLower.contains('jagjit singh') ||
        artistLower.contains('kalyanji') ||
        artistLower.contains('laxmikant') ||
        artistLower.contains('pyarelal') ||
        artistLower.contains('anuradha paudwal') ||
        artistLower.contains('kumar sanu') ||
        artistLower.contains('alka yagnik') ||
        artistLower.contains('udit narayan') ||
        artistLower.contains('pankaj udhas') ||
        artistLower.contains('chitra singh') ||
        artistLower.contains('bhupinder') ||
        artistLower.contains('salil chowdhury') ||
        artistLower.contains('naushad') ||
        artistLower.contains('mubarak begum') ||
        artistLower.contains('sadhana sargam') ||
        artistLower.contains('kavita krishnamurthy') ||
        artistLower.contains('hariharan') ||
        artistLower.contains('bappi lahiri') ||
        artistLower.contains('roop kumar rathod') ||
        artistLower.contains('mahendra kapoor') ||
        artistLower.contains('shankar jaikishan') ||
        artistLower.contains('madan mohan') ||
        artistLower.contains('khayyam') ||
        artistLower.contains('o.p. nayyar') ||
        titleLower.contains('sajna hai mujhe') ||
        titleLower.contains('lag ja gale') ||
        titleLower.contains('pal pal dil') ||
        titleLower.contains('roop tera') ||
        titleLower.contains('kabhie kabhie') ||
        titleLower.contains('mere sapno ki') ||
        titleLower.contains('pyar kiya to') ||
        titleLower.contains('tere bina zindagi') ||
        titleLower.contains('ek ajnabee haseena') ||
        titleLower.contains('gulabi aankhen') ||
        titleLower.contains('chaudhvin ka chand') ||
        titleLower.contains('chura liya') ||
        titleLower.contains('yeh dosti') ||
        genreLower.contains('retro') ||
        genreLower.contains('classic') ||
        genreLower.contains('old') ||
        genreLower.contains('60s') ||
        genreLower.contains('70s') ||
        genreLower.contains('80s') ||
        genreLower.contains('90s') ||
        genreLower.contains('evergreen') ||
        genreLower.contains('ghazal') ||
        genreLower.contains('purane') ||
        genreLower.contains('golden');
  }

  /// Checks if a song belongs to the 2000s-2010s Bollywood Soulful / Emraan Hashmi Era
  static bool is2000sSong(Song song) {
    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();

    return artistLower.contains('kk') ||
        artistLower.contains('krishnakumar') ||
        artistLower.contains('mohit chauhan') ||
        artistLower.contains('atif aslam') ||
        artistLower.contains('himesh reshammiya') ||
        artistLower.contains('lucky ali') ||
        artistLower.contains('rahat fateh') ||
        artistLower.contains('shafqat') ||
        artistLower.contains('kunal ganjawala') ||
        artistLower.contains('zubeen garg') ||
        artistLower.contains('mustafa zahid') ||
        artistLower.contains('jal') ||
        artistLower.contains('roxen') ||
        artistLower.contains('euphoria') ||
        artistLower.contains('strings') ||
        artistLower.contains('adnan sami') ||
        artistLower.contains('kailash kher') ||
        titleLower.contains('woh lamhe') ||
        titleLower.contains('tu hi meri shab') ||
        titleLower.contains('labon ko') ||
        titleLower.contains('kya mujhe pyar hai') ||
        titleLower.contains('zara sa') ||
        titleLower.contains('peehloon') ||
        titleLower.contains('saibo') ||
        titleLower.contains('mitwa') ||
        titleLower.contains('alvida') ||
        titleLower.contains('aadat');
  }

  /// Checks if a song belongs to Punjabi / Desi Hip Hop
  static bool isPunjabiOrHipHopSong(Song song) {
    final artistLower = song.artist.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    return artistLower.contains('karan aujla') ||
        artistLower.contains('diljit') ||
        artistLower.contains('sidhu moose') ||
        artistLower.contains('shubh') ||
        artistLower.contains('ap dhillon') ||
        artistLower.contains('bohemia') ||
        artistLower.contains('talwiinder') ||
        artistLower.contains('king') ||
        artistLower.contains('seedhe maut') ||
        artistLower.contains('kr\$na') ||
        artistLower.contains('divine') ||
        artistLower.contains('raftaar') ||
        artistLower.contains('mc stan') ||
        artistLower.contains('hanumankind') ||
        artistLower.contains('honey singh') ||
        artistLower.contains('badshah') ||
        artistLower.contains('guru randhawa') ||
        artistLower.contains('b praak') ||
        artistLower.contains('jassie gill') ||
        artistLower.contains('harrdy sandhu') ||
        artistLower.contains('ammy virk') ||
        artistLower.contains('parmish verma') ||
        genreLower.contains('punjabi') ||
        genreLower.contains('hip hop') ||
        genreLower.contains('rap');
  }

  /// Checks if a song belongs to Indie / Acoustic / Sukoon
  static bool isIndieOrSukoonSong(Song song) {
    final artistLower = song.artist.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    return artistLower.contains('anuv jain') ||
        artistLower.contains('prateek kuhad') ||
        artistLower.contains('jasleen royal') ||
        artistLower.contains('aditya a') ||
        artistLower.contains('mitraz') ||
        artistLower.contains('aur') ||
        artistLower.contains('kaifi khalil') ||
        artistLower.contains('faheem abdullah') ||
        artistLower.contains('kushagra') ||
        artistLower.contains('bharat chauhan') ||
        artistLower.contains('local train') ||
        artistLower.contains('coke studio') ||
        genreLower.contains('indie') ||
        genreLower.contains('acoustic') ||
        genreLower.contains('sukoon') ||
        genreLower.contains('lo-fi') ||
        genreLower.contains('chill');
  }

  /// Discovers 50-60 related, era-pure songs matching the seed song's era, artist,
  /// style and mood for uninterrupted "Continue Playing".
  static Future<List<Song>> fetchSmartRecommendations(Song seedSong, {int limit = 55}) async {
    final List<Song> recommendations = [];
    final Set<String> seenIds = {seedSong.id};
    final Set<String> seenTitles = {seedSong.title.toLowerCase().trim()};

    final rawArtist = seedSong.artist
        .split(',')
        .first
        .split('&')
        .first
        .split('feat.')
        .first
        .trim();

    final isOld = isOldClassicSong(seedSong);
    final is2000s = !isOld && is2000sSong(seedSong);
    final isPunjabi = !isOld && !is2000s && isPunjabiOrHipHopSong(seedSong);
    final isIndie = !isOld && !is2000s && !isPunjabi && isIndieOrSukoonSong(seedSong);

    final List<Future<List<Song>>> futures = [];

    if (rawArtist.isNotEmpty &&
        rawArtist.toLowerCase() != 'unknown artist' &&
        rawArtist.toLowerCase() != 'music') {
      futures.add(searchLiveSongs('$rawArtist hits', limit: 15).catchError((_) => <Song>[]));
    }

    if (isOld) {
      // STRICT PURANE GAANE (Evergreen 60s, 70s, 80s, 90s Golden Era Classics Only)
      futures.add(searchLiveSongs('Kishore Kumar Evergreen Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Lata Mangeshkar Golden Era Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Mohammed Rafi Classic Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('RD Burman 70s 80s Superhits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('90s Melodies Kumar Sanu Alka Yagnik Udit Narayan', limit: 15).catchError((_) => <Song>[]));
      futures.add(fetch90sDuets().catchError((_) => <Song>[]));
    } else if (is2000s) {
      // 2000s - 2010s Bollywood Nostalgia / Emraan Hashmi Era / Soulful Hits
      futures.add(searchLiveSongs('2000s Bollywood Romantic Nostalgia', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('KK Best Soulful Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Atif Aslam 2000s Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Mohit Chauhan Soulful Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Emraan Hashmi Era Romantic Hits', limit: 15).catchError((_) => <Song>[]));
    } else if (isPunjabi) {
      // Punjabi Hits & Desi Hip Hop
      futures.add(searchLiveSongs('Karan Aujla New Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Diljit Dosanjh Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('AP Dhillon Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Sidhu Moosewala Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Top Punjabi Chartbusters', limit: 15).catchError((_) => <Song>[]));
    } else if (isIndie) {
      // Indie & Sukoon Hits
      futures.add(searchLiveSongs('Indie India Sukoon Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Anuv Jain Prateek Kuhad Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Acoustic Hindi Sukoon Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Coke Studio Soulful Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(fetchBestOfIndie().catchError((_) => <Song>[]));
    } else {
      // Modern Bollywood & Top 50 Chartbusters
      futures.add(searchLiveSongs('Trending Bollywood Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Top Bollywood Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(fetchTrendingToday().catchError((_) => <Song>[]));
      futures.add(fetchIndiaTop50().catchError((_) => <Song>[]));
    }

    try {
      final results = await Future.wait(futures);
      for (final songList in results) {
        for (final song in songList) {
          final lowerTitle = song.title.toLowerCase().trim();

          // If old classic was requested, strictly exclude modern hip-hop / modern drill
          if (isOld && isPunjabiOrHipHopSong(song)) {
            continue;
          }

          if (!seenIds.contains(song.id) &&
              !seenTitles.contains(lowerTitle) &&
              !lowerTitle.contains(seedSong.title.toLowerCase()) &&
              song.audioUrl.isNotEmpty) {
            seenIds.add(song.id);
            seenTitles.add(lowerTitle);
            recommendations.add(song);
          }
        }
      }
    } catch (_) {}

    return recommendations.take(limit).toList();
  }
}

