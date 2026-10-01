import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../config/app_config.dart';

class MusicApiService {
  static String get _endpoint => AppConfig.supabaseEndpoint;
  static Map<String, String> get _headers => AppConfig.apiHeaders;

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
    String result = '';
    if (imageObj is String) {
      result = imageObj;
    } else if (imageObj is List && imageObj.isNotEmpty) {
      for (final item in imageObj.reversed) {
        if (item is Map) {
          final url = (item['url'] as String?) ?? (item['link'] as String?) ?? '';
          if (url.isNotEmpty) {
            result = url;
            break;
          }
        } else if (item is String && item.isNotEmpty) {
          result = item;
          break;
        }
      }
      if (result.isEmpty && imageObj.first is Map) {
        result = (imageObj.first['url'] as String?) ?? (imageObj.first['link'] as String?) ?? '';
      }
    } else if (imageObj is Map) {
      result = (imageObj['url'] as String?) ?? (imageObj['link'] as String?) ?? '';
    }

    result = result.trim();
    if (result.isEmpty) return '';

    // Always ensure secure HTTPS for web browser compatibility
    if (result.startsWith('http://')) {
      result = result.replaceFirst('http://', 'https://');
    }

    // Upgrade low resolution thumbnails to crisp 500x500
    if (result.contains('150x150')) {
      result = result.replaceAll('150x150', '500x500');
    } else if (result.contains('50x50')) {
      result = result.replaceAll('50x50', '500x500');
    }

    return result;
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

      // Extract language from metadata if present
      String rawLang = (item['language'] as String?) ??
          (item['lang'] as String?) ??
          '';
      rawLang = rawLang.trim().toLowerCase();
      if (rawLang.isEmpty) {
        rawLang = 'hindi';
      }

      String normalizedLang = 'Hindi';
      if (rawLang.contains('punjabi')) {
        normalizedLang = 'Punjabi';
      } else if (rawLang.contains('tamil')) {
        normalizedLang = 'Tamil';
      } else if (rawLang.contains('telugu')) {
        normalizedLang = 'Telugu';
      } else if (rawLang.contains('english')) {
        normalizedLang = 'English';
      } else if (rawLang.contains('bhojpuri')) {
        normalizedLang = 'Bhojpuri';
      } else if (rawLang.contains('haryanvi')) {
        normalizedLang = 'Haryanvi';
      }

      return Song(
        id: id,
        title: name,
        artist: artist,
        album: album.isNotEmpty ? album : 'Single',
        duration: Duration(seconds: durationSec),
        audioUrl: audioUrl,
        coverUrl: coverUrl.isNotEmpty
            ? coverUrl
            : 'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
        genre: normalizedLang == 'Hindi' ? 'Hindi & Bollywood' : normalizedLang,
        language: normalizedLang,
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
          .timeout(const Duration(seconds: 10));

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
          .timeout(const Duration(seconds: 10));

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
          .timeout(const Duration(seconds: 8));

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

  // -------------------------------------------------------------
  // LANGUAGE & ERA DETECTION SYSTEM
  // -------------------------------------------------------------

  /// Detects language of a song (Hindi, Punjabi, South, English, Bhojpuri, Haryanvi)
  static String detectSongLanguage(Song song) {
    final titleLower = song.title.toLowerCase();
    final artistLower = song.artist.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();
    final langLower = song.language.toLowerCase();

    // 1. Explicit Hindi words in title (Never treat as English if title has Hindi words)
    final bool hasHindiWords = titleLower.contains('dil') ||
        titleLower.contains('pyar') ||
        titleLower.contains('pyaar') ||
        titleLower.contains('ishq') ||
        titleLower.contains('tere') ||
        titleLower.contains('teri') ||
        titleLower.contains('tera') ||
        titleLower.contains('tum') ||
        titleLower.contains('hum') ||
        titleLower.contains('chalein') ||
        titleLower.contains('aao') ||
        titleLower.contains('kya') ||
        titleLower.contains('hai') ||
        titleLower.contains('hain') ||
        titleLower.contains('zindagi') ||
        titleLower.contains('sukoon') ||
        titleLower.contains('mohabbat') ||
        titleLower.contains('saath') ||
        titleLower.contains('raatein') ||
        titleLower.contains('baatein') ||
        titleLower.contains('jaana') ||
        titleLower.contains('deewana') ||
        titleLower.contains('sanam') ||
        titleLower.contains('chura') ||
        titleLower.contains('aaja') ||
        titleLower.contains('naina') ||
        titleLower.contains('akhiyaan') ||
        titleLower.contains('dholna') ||
        titleLower.contains('rabba') ||
        titleLower.contains('meri') ||
        titleLower.contains('mera') ||
        titleLower.contains('mere') ||
        titleLower.contains('musafir') ||
        titleLower.contains('dard') ||
        titleLower.contains('intezaar');

    if (hasHindiWords && !albumLower.contains('english')) {
      return 'Hindi';
    }

    if (langLower.contains('punjabi') || genreLower.contains('punjabi') || albumLower.contains('punjabi')) return 'Punjabi';
    if (langLower.contains('tamil') || langLower.contains('telugu') || langLower.contains('kannada') || langLower.contains('malayalam') || genreLower.contains('tamil') || genreLower.contains('telugu') || genreLower.contains('south')) return 'South';
    if (langLower.contains('bhojpuri') || genreLower.contains('bhojpuri')) return 'Bhojpuri';
    if (langLower.contains('haryanvi') || genreLower.contains('haryanvi')) return 'Haryanvi';

    // 2. English Indicators
    if (langLower.contains('english') ||
        langLower.contains('western') ||
        genreLower.contains('english') ||
        albumLower.contains('english') ||
        albumLower.contains('billboard') ||
        albumLower.contains('global') ||
        albumLower.contains('hollywood') ||
        artistLower.contains('taylor swift') ||
        artistLower.contains('the weeknd') ||
        artistLower.contains('drake') ||
        artistLower.contains('ed sheeran') ||
        artistLower.contains('justin bieber') ||
        artistLower.contains('dua lipa') ||
        artistLower.contains('billie eilish') ||
        artistLower.contains('bruno mars') ||
        artistLower.contains('coldplay') ||
        artistLower.contains('post malone') ||
        artistLower.contains('maroon 5') ||
        artistLower.contains('charlie puth') ||
        artistLower.contains('shawn mendes') ||
        artistLower.contains('selena gomez') ||
        artistLower.contains('ariana grande') ||
        artistLower.contains('eminem') ||
        artistLower.contains('adele') ||
        artistLower.contains('rihanna') ||
        artistLower.contains('hanumankind') ||
        artistLower.contains('parekh & singh') ||
        artistLower.contains('when chai met toast') ||
        artistLower.contains('raghav meattle') ||
        artistLower.contains('tsumyoki')) {
      return 'English';
    }

    // Check specific English track titles
    if (titleLower == 'blush' ||
        titleLower == 'co2' ||
        titleLower.contains('mess') ||
        titleLower.contains('doll') ||
        titleLower.contains('unicorn') ||
        titleLower.contains('pink blue') ||
        titleLower.contains('when we feel young') ||
        titleLower.contains('big dawgs')) {
      return 'English';
    }

    // Punjabi Artists
    if (artistLower.contains('karan aujla') ||
        artistLower.contains('diljit') ||
        artistLower.contains('sidhu moose') ||
        artistLower.contains('ap dhillon') ||
        artistLower.contains('shubh') ||
        artistLower.contains('bohemia') ||
        artistLower.contains('talwiinder') ||
        artistLower.contains('ammy virk') ||
        artistLower.contains('b praak') ||
        artistLower.contains('parmish verma')) {
      return 'Punjabi';
    }

    // South Artists
    if (artistLower.contains('anirudh') ||
        artistLower.contains('sid sriram') ||
        artistLower.contains('devi sri prasad') ||
        artistLower.contains('ilaiyaraaja') ||
        artistLower.contains('thaman') ||
        artistLower.contains('santhosh narayanan') ||
        artistLower.contains('harris jayaraj') ||
        artistLower.contains('yuvan shankar') ||
        artistLower.contains('spb') ||
        artistLower.contains('chithra')) {
      return 'South';
    }

    // Bhojpuri
    if (artistLower.contains('pawan singh') ||
        artistLower.contains('khesari') ||
        artistLower.contains('shilpi raj') ||
        artistLower.contains('nirahua') ||
        titleLower.contains('lollipop')) {
      return 'Bhojpuri';
    }

    // Haryanvi
    if (artistLower.contains('gulzaar chhaniwala') ||
        artistLower.contains('renuka panwar') ||
        artistLower.contains('diler kharkiya')) {
      return 'Haryanvi';
    }

    return 'Hindi';
  }

  /// Checks if a song belongs to the 1950s - 1970s Vintage Golden Era
  static bool isVintageGoldenEra(Song song) {
    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 1940 && year < 1980) {
      return true;
    }

    // Iconic 50s-70s film & track titles
    if (albumLower.contains('baharon ke sapne') ||
        albumLower.contains('aradhana') ||
        albumLower.contains('anand') ||
        albumLower.contains('sholay') ||
        albumLower.contains('kati patang') ||
        albumLower.contains('amar prem') ||
        albumLower.contains('pakeezah') ||
        albumLower.contains('mughal-e-azam') ||
        albumLower.contains('guide') ||
        albumLower.contains('hum kisise kum naheen') ||
        albumLower.contains('kabhie kabhie') ||
        albumLower.contains('silsila') ||
        titleLower.contains('aaja piya tohe') ||
        titleLower.contains('lag ja gale') ||
        titleLower.contains('pal pal dil') ||
        titleLower.contains('roop tera mastana') ||
        titleLower.contains('mere sapno ki rani') ||
        titleLower.contains('gulabi aankhen') ||
        titleLower.contains('chaudhvin ka chand') ||
        titleLower.contains('chura liya hai tumne') ||
        titleLower.contains('tere bina zindagi se') ||
        titleLower.contains('pyar kiya to darna kya') ||
        titleLower.contains('panna ki tamanna') ||
        titleLower.contains('ek ajnabee haseena')) {
      return true;
    }

    // Exclusive Vintage Legends (before 1980)
    final isClassicSinger = artistLower.contains('kishore kumar') ||
        artistLower.contains('mohammed rafi') ||
        artistLower.contains('mohd rafi') ||
        artistLower.contains('mukesh') ||
        artistLower.contains('hemant kumar') ||
        artistLower.contains('talat mahmood') ||
        artistLower.contains('manna dey') ||
        artistLower.contains('geeta dutt') ||
        artistLower.contains('s. d. burman') ||
        artistLower.contains('sd burman') ||
        artistLower.contains('naushad') ||
        artistLower.contains('madan mohan') ||
        artistLower.contains('o.p. nayyar') ||
        artistLower.contains('salil chowdhury') ||
        artistLower.contains('khayyam');

    if (isClassicSinger) {
      if (year == null || year < 1980 || year >= 2024) {
        return true;
      }
    }

    // Lata Mangeshkar / Asha Bhosle vintage check
    if ((artistLower.contains('lata mangeshkar') || artistLower.contains('asha bhosle')) &&
        !artistLower.contains('kumar sanu') &&
        !artistLower.contains('udit narayan') &&
        !artistLower.contains('sonu nigam') &&
        !artistLower.contains('arijit') &&
        !titleLower.contains('dil to pagal hai') &&
        !titleLower.contains('tujhe dekha to') &&
        !titleLower.contains('andekhi anjaani') &&
        !titleLower.contains('humko humise') &&
        !titleLower.contains('tere liye') &&
        !titleLower.contains('kabhi khushi') &&
        !titleLower.contains('zubi zubi') &&
        !titleLower.contains('radha kaise na jale')) {
      if (year == null || year < 1980 || year >= 2024) {
        return true;
      }
    }

    return genreLower.contains('retro') ||
        genreLower.contains('golden') ||
        genreLower.contains('purane') ||
        genreLower.contains('60s') ||
        genreLower.contains('70s');
  }

  /// Checks if a song belongs to the 1980s Era (Bappi Lahiri, Disco, Chandni, Tezaab, QSQT)
  static bool is80sEra(Song song) {
    if (isVintageGoldenEra(song)) return false;

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 1980 && year < 1990) {
      return true;
    }

    return artistLower.contains('bappi lahiri') ||
        artistLower.contains('amit kumar') ||
        artistLower.contains('shabbir kumar') ||
        artistLower.contains('mohammed aziz') ||
        artistLower.contains('salma agha') ||
        artistLower.contains('nazia hassan') ||
        artistLower.contains('alisha chinai') ||
        albumLower.contains('disco dancer') ||
        albumLower.contains('chandni') ||
        albumLower.contains('tezaab') ||
        albumLower.contains('qayamat se qayamat tak') ||
        albumLower.contains('mr. india') ||
        albumLower.contains('mr india') ||
        albumLower.contains('himmatwala') ||
        albumLower.contains('karz') ||
        albumLower.contains('hero (1983)') ||
        albumLower.contains('maine pyar kiya') ||
        albumLower.contains('tridev') ||
        albumLower.contains('ram lakhan') ||
        titleLower.contains('i am a disco dancer') ||
        titleLower.contains('jimmy jimmy') ||
        titleLower.contains('ek do teen') ||
        titleLower.contains('mere haathon mein') ||
        titleLower.contains('papa kehte hain') ||
        titleLower.contains('gazab ka hai din') ||
        titleLower.contains('hawa hawai') ||
        titleLower.contains('dil deewana') ||
        titleLower.contains('kabootar ja ja') ||
        genreLower.contains('80s');
  }

  /// Checks if a song belongs to the 1990s Melodies Era (Kumar Sanu, Alka Yagnik, Udit Narayan, DDLJ, Saajan)
  static bool is90sMelodyEra(Song song) {
    if (isVintageGoldenEra(song) || is80sEra(song)) return false;

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 1990 && year < 2000) {
      return true;
    }

    return artistLower.contains('kumar sanu') ||
        artistLower.contains('alka yagnik') ||
        artistLower.contains('udit narayan') ||
        artistLower.contains('anuradha paudwal') ||
        artistLower.contains('sadhana sargam') ||
        artistLower.contains('kavita krishnamurthy') ||
        artistLower.contains('abhijeet') ||
        artistLower.contains('pankaj udhas') ||
        artistLower.contains('roop kumar rathod') ||
        artistLower.contains('nadeem') ||
        artistLower.contains('shravan') ||
        artistLower.contains('jatin') ||
        artistLower.contains('lalit') ||
        albumLower.contains('aashiqui') ||
        albumLower.contains('saajan') ||
        albumLower.contains('dil to pagal hai') ||
        albumLower.contains('kuch kuch hota hai') ||
        albumLower.contains('raja hindustani') ||
        albumLower.contains('baazigar') ||
        albumLower.contains('hum aapke hain koun') ||
        albumLower.contains('pardes') ||
        albumLower.contains('mohra') ||
        albumLower.contains('border') ||
        albumLower.contains('kaho naa... pyaar hai') ||
        titleLower.contains('dil to pagal hai') ||
        titleLower.contains('tujhe dekha to') ||
        titleLower.contains('chura ke dil mera') ||
        titleLower.contains('tip tip barsa') ||
        titleLower.contains('aashiqui') ||
        titleLower.contains('saajan') ||
        titleLower.contains('kuch kuch hota hai') ||
        titleLower.contains('raja hindustani') ||
        titleLower.contains('baazigar') ||
        titleLower.contains('hum aapke hain koun') ||
        titleLower.contains('dilwale dulhania') ||
        genreLower.contains('90s');
  }

  /// Checks if a song belongs to the 2000s - 2009 Bollywood Soulful / Emraan Hashmi Era / KK
  static bool is2000sSong(Song song) {
    if (isVintageGoldenEra(song) || is80sEra(song) || is90sMelodyEra(song)) return false;

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 2000 && year < 2010) {
      return true;
    }

    return artistLower.contains('kk') ||
        artistLower.contains('krishnakumar') ||
        artistLower.contains('shaan') ||
        artistLower.contains('lucky ali') ||
        artistLower.contains('himesh reshammiya') ||
        artistLower.contains('kailash kher') ||
        artistLower.contains('adnan sami') ||
        artistLower.contains('zubeen garg') ||
        artistLower.contains('kunal ganjawala') ||
        artistLower.contains('mustafa zahid') ||
        artistLower.contains('jal') ||
        artistLower.contains('roxen') ||
        artistLower.contains('strings') ||
        albumLower.contains('tere naam') ||
        albumLower.contains('kal ho naa ho') ||
        albumLower.contains('main hoon na') ||
        albumLower.contains('veer-zaara') ||
        albumLower.contains('jab we met') ||
        albumLower.contains('fanaa') ||
        albumLower.contains('jannat') ||
        albumLower.contains('gangster') ||
        albumLower.contains('murder') ||
        albumLower.contains('awarapan') ||
        titleLower.contains('woh lamhe') ||
        titleLower.contains('tu hi meri shab') ||
        titleLower.contains('labon ko') ||
        titleLower.contains('kya mujhe pyar hai') ||
        titleLower.contains('zara sa') ||
        titleLower.contains('peehloon') ||
        titleLower.contains('mitwa') ||
        titleLower.contains('alvida') ||
        titleLower.contains('aadat');
  }

  /// Checks if a song belongs to the 2010s (2010 - 2019) Arijit Singh / Modern Romantic Era
  static bool is2010sSong(Song song) {
    if (isVintageGoldenEra(song) || is80sEra(song) || is90sMelodyEra(song) || is2000sSong(song)) return false;

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 2010 && year < 2020) {
      return true;
    }

    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();

    return albumLower.contains('aashiqui 2') ||
        albumLower.contains('kabir singh') ||
        albumLower.contains('yeh jawaani hai deewani') ||
        albumLower.contains('rockstar') ||
        albumLower.contains('sanam re') ||
        albumLower.contains('ae dil hai mushkil') ||
        albumLower.contains('raabta') ||
        titleLower.contains('tum hi ho') ||
        titleLower.contains('channa mereya') ||
        titleLower.contains('gerua') ||
        titleLower.contains('bekhayali') ||
        titleLower.contains('shayad') ||
        titleLower.contains('hawayein');
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
        artistLower.contains('bharat chauhan') ||
        artistLower.contains('local train') ||
        genreLower.contains('indie') ||
        genreLower.contains('acoustic') ||
        genreLower.contains('sukoon') ||
        genreLower.contains('lo-fi');
  }

  /// Discovers 50-60 related, strictly era-pure and language-pure songs matching the seed song's
  /// era, language, artist, and mood for uninterrupted "Continue Playing".
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

    final songLanguage = detectSongLanguage(seedSong);
    final is70s = songLanguage == 'Hindi' && isVintageGoldenEra(seedSong);
    final is80s = songLanguage == 'Hindi' && !is70s && is80sEra(seedSong);
    final is90s = songLanguage == 'Hindi' && !is70s && !is80s && is90sMelodyEra(seedSong);
    final is2000s = songLanguage == 'Hindi' && !is70s && !is80s && !is90s && is2000sSong(seedSong);
    final is2010s = songLanguage == 'Hindi' && !is70s && !is80s && !is90s && !is2000s && is2010sSong(seedSong);
    final isIndie = songLanguage == 'Hindi' && !is70s && !is80s && !is90s && !is2000s && !is2010s && isIndieOrSukoonSong(seedSong);

    final List<Future<List<Song>>> futures = [];

    // 1. Artist-specific query tailored by era
    if (rawArtist.isNotEmpty &&
        rawArtist.toLowerCase() != 'unknown artist' &&
        rawArtist.toLowerCase() != 'music') {
      if (is70s) {
        futures.add(searchLiveSongs('$rawArtist 60s 70s golden hits', limit: 15).catchError((_) => <Song>[]));
      } else if (is80s) {
        futures.add(searchLiveSongs('$rawArtist 80s disco romantic hits', limit: 15).catchError((_) => <Song>[]));
      } else if (is90s) {
        futures.add(searchLiveSongs('$rawArtist 90s romantic melodies', limit: 15).catchError((_) => <Song>[]));
      } else if (is2000s) {
        futures.add(searchLiveSongs('$rawArtist 2000s romantic hits', limit: 15).catchError((_) => <Song>[]));
      } else if (is2010s) {
        futures.add(searchLiveSongs('$rawArtist romantic hits', limit: 15).catchError((_) => <Song>[]));
      } else if (songLanguage == 'English') {
        futures.add(searchLiveSongs('$rawArtist English pop indie acoustic hits', limit: 15).catchError((_) => <Song>[]));
      } else if (songLanguage == 'Punjabi') {
        futures.add(searchLiveSongs('$rawArtist Punjabi hits', limit: 15).catchError((_) => <Song>[]));
      } else if (songLanguage == 'South') {
        futures.add(searchLiveSongs('$rawArtist South hits', limit: 15).catchError((_) => <Song>[]));
      } else {
        futures.add(searchLiveSongs('$rawArtist hits', limit: 15).catchError((_) => <Song>[]));
      }
    }

    // 2. Language & Era Specific Recommendations
    if (songLanguage == 'Punjabi') {
      // STRICT PUNJABI
      futures.add(searchLiveSongs('Karan Aujla New Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Diljit Dosanjh Superhits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('AP Dhillon Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Sidhu Moosewala Superhits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Top Punjabi Chartbusters 2024', limit: 15).catchError((_) => <Song>[]));
    } else if (songLanguage == 'South') {
      // STRICT SOUTH (TAMIL & TELUGU)
      futures.add(searchLiveSongs('Anirudh Ravichander Tamil Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Sid Sriram Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Top Tamil Superhits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Telugu Chartbusters', limit: 15).catchError((_) => <Song>[]));
    } else if (songLanguage == 'English') {
      // STRICT ENGLISH
      futures.add(searchLiveSongs('Billboard Hot 100 English Pop Hits', limit: 20).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Global English Superhits Chart', limit: 20).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Acoustic English Indie Melodies', limit: 20).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Best of Indie English acoustic', limit: 20).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Global Acoustic Pop English Hits', limit: 20).catchError((_) => <Song>[]));
    } else if (songLanguage == 'Bhojpuri') {
      // STRICT BHOJPURI
      futures.add(searchLiveSongs('Pawan Singh Bhojpuri Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Khesari Lal Superhits', limit: 15).catchError((_) => <Song>[]));
    } else if (songLanguage == 'Haryanvi') {
      // STRICT HARYANVI
      futures.add(searchLiveSongs('Gulzaar Chhaniwala Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Top Haryanvi Chartbusters', limit: 15).catchError((_) => <Song>[]));
    } else if (is70s) {
      // STRICT 50s-70s GOLDEN ERA (Kishore, Lata Vintage, Rafi, Mukesh, SD/RD Burman)
      // Strictly NO 80s, NO 90s, NO 2000s!
      futures.add(searchLiveSongs('Kishore Kumar 70s Evergreen Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Lata Mangeshkar 60s 70s Golden Era Classics', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Mohammed Rafi 60s 70s Classic Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Mukesh Golden Era Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('RD Burman SD Burman 60s 70s Superhits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Vintage Bollywood Golden Classics 60s 70s', limit: 15).catchError((_) => <Song>[]));
    } else if (is80s) {
      // STRICT 80s BOLLYWOOD (Bappi Lahiri, Disco Dancer, Tezaab, Chandni, QSQT)
      // Strictly NO 70s, NO 90s!
      futures.add(searchLiveSongs('80s Bollywood Disco Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Bappi Lahiri 80s Superhits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('80s Bollywood Romantic Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Amit Kumar 80s Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Chandni Tezaab QSQT 80s Songs', limit: 15).catchError((_) => <Song>[]));
    } else if (is90s) {
      // STRICT 90s BOLLYWOOD MELODIES (Kumar Sanu, Alka Yagnik, Udit Narayan, DDLJ, Saajan)
      // Strictly NO 70s, NO 80s, NO 2000s!
      futures.add(searchLiveSongs('Kumar Sanu Alka Yagnik 90s Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Udit Narayan 90s Evergreen Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Nadeem Shravan 90s Magic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('90s Bollywood Evergreen Romantic Songs', limit: 15).catchError((_) => <Song>[]));
      futures.add(fetch90sDuets().catchError((_) => <Song>[]));
    } else if (is2000s) {
      // STRICT 2000s BOLLYWOOD NOSTALGIA / EMRAAN HASHMI ERA / KK
      futures.add(searchLiveSongs('2000s Bollywood Romantic Nostalgia', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('KK Best Soulful Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Atif Aslam 2000s Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Mohit Chauhan 2000s Soulful Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Emraan Hashmi Era Romantic Hits', limit: 15).catchError((_) => <Song>[]));
    } else if (is2010s) {
      // STRICT 2010s BOLLYWOOD (Arijit Singh, Aashiqui 2, Kabir Singh, Armaan Malik)
      futures.add(searchLiveSongs('Arijit Singh 2010s Romantic Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Aashiqui 2 Kabir Singh Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('2010s Bollywood Superhit Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Armaan Malik Jubin Nautiyal Romantic Hits', limit: 15).catchError((_) => <Song>[]));
    } else if (isIndie) {
      // INDIE & SUKOON
      futures.add(searchLiveSongs('Indie India Sukoon Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Anuv Jain Prateek Kuhad Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Acoustic Hindi Sukoon Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(fetchBestOfIndie().catchError((_) => <Song>[]));
    } else {
      // MODERN BOLLYWOOD / 2020+ RELEASES
      futures.add(searchLiveSongs('Darshan Raval Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Arijit Singh Modern Romantic Hits', limit: 15).catchError((_) => <Song>[]));
      futures.add(searchLiveSongs('Trending Bollywood Romantic Melodies', limit: 15).catchError((_) => <Song>[]));
      futures.add(fetchTrendingToday().catchError((_) => <Song>[]));
      futures.add(fetchIndiaTop50().catchError((_) => <Song>[]));
    }

    try {
      final results = await Future.wait(futures);
      for (final songList in results) {
        for (final song in songList) {
          final lowerTitle = song.title.toLowerCase().trim();

          // 1. Language matching filter
          final candLanguage = detectSongLanguage(song);
          if (candLanguage != songLanguage) {
            continue;
          }

          if (songLanguage == 'English') {
            final tLower = song.title.toLowerCase();
            final aLower = song.artist.toLowerCase();
            if (tLower.contains('dil') ||
                tLower.contains('pyar') ||
                tLower.contains('chalein') ||
                tLower.contains('aao') ||
                tLower.contains('tere') ||
                tLower.contains('meri') ||
                tLower.contains('ishq') ||
                tLower.contains('tum') ||
                tLower.contains('hum') ||
                tLower.contains('zindagi') ||
                tLower.contains('sukoon') ||
                aLower.contains('arijit') ||
                aLower.contains('kumar sanu') ||
                aLower.contains('alka yagnik') ||
                aLower.contains('udit narayan') ||
                aLower.contains('lata mangeshkar') ||
                aLower.contains('kishore kumar')) {
              continue;
            }
          }

          // 2. Strict Era matching filter for Hindi
          if (songLanguage == 'Hindi') {
            if (is70s) {
              // Strictly 70s golden era
              if (!isVintageGoldenEra(song) || is80sEra(song) || is90sMelodyEra(song) || is2000sSong(song) || is2010sSong(song)) {
                continue;
              }
            } else if (is80s) {
              // Strictly 80s
              if (isVintageGoldenEra(song) || is90sMelodyEra(song) || is2000sSong(song) || is2010sSong(song)) {
                continue;
              }
            } else if (is90s) {
              // Strictly 90s melodies
              if (isVintageGoldenEra(song) || is80sEra(song) || is2000sSong(song) || is2010sSong(song)) {
                continue;
              }
            } else if (is2000s) {
              // Strictly 2000s
              if (isVintageGoldenEra(song) || is80sEra(song) || is90sMelodyEra(song) || is2010sSong(song)) {
                continue;
              }
            }
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


