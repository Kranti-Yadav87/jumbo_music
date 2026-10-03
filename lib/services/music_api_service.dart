import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../config/app_config.dart';
import 'release_filter.dart';
import 'api/song_parser_utils.dart';
import 'api/music_tag_classifier.dart';
import 'api/itunes_search_service.dart';

export 'api/song_parser_utils.dart';
export 'api/music_tag_classifier.dart';
export 'api/itunes_search_service.dart';

class MusicApiService {
  static String get _endpoint => AppConfig.supabaseEndpoint;
  static Map<String, String> get _headers => AppConfig.apiHeaders;

  // Delegates to SongParserUtils for internal / backward compatibility
  static String unescape(String? input) => SongParserUtils.unescape(input);
  static String extractImage(dynamic imageObj) =>
      SongParserUtils.extractImage(imageObj);
  static String extractAudioUrl(dynamic downloadUrlObj) =>
      SongParserUtils.extractAudioUrl(downloadUrlObj);
  static String extractArtists(dynamic item) =>
      SongParserUtils.extractArtists(item);
  static Song? parseSong(Map<String, dynamic> item) =>
      SongParserUtils.parseSong(item);

  // Delegates to MusicTagClassifier
  static String detectSongLanguage(Song song) =>
      MusicTagClassifier.detectSongLanguage(song);
  static bool isVintageGoldenEra(Song song) =>
      MusicTagClassifier.isVintageGoldenEra(song);
  static bool is80sEra(Song song) => MusicTagClassifier.is80sEra(song);
  static bool is90sMelodyEra(Song song) =>
      MusicTagClassifier.is90sMelodyEra(song);
  static bool is2000sSong(Song song) => MusicTagClassifier.is2000sSong(song);
  static bool is2010sSong(Song song) => MusicTagClassifier.is2010sSong(song);
  static bool isIndieOrSukoonSong(Song song) =>
      MusicTagClassifier.isIndieOrSukoonSong(song);

  /// Live Search matching aura-stream-henna.vercel.app
  static Future<List<Song>> searchLiveSongs(
    String query, {
    int limit = 30,
  }) async {
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
            final song = SongParserUtils.parseSong(item);
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

        final name = SongParserUtils.unescape(
          pData['name'] ?? pData['title'] ?? 'Playlist',
        );
        final coverUrl = SongParserUtils.extractImage(pData['image']);
        final songList = pData['songs'] ?? pData['list'] ?? [];

        final List<Song> songs = [];
        if (songList is List) {
          for (final item in songList) {
            if (item is Map<String, dynamic>) {
              final song = SongParserUtils.parseSong(item);
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
    return {
      'id': playlistId,
      'name': 'Playlist',
      'coverUrl': '',
      'songs': <Song>[],
    };
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

  /// Languages shown on the home screen (label -> search phrase).
  static const Map<String, String> homeLanguages = {
    'Hindi': 'latest hindi songs',
    'English': 'english pop hits',
    'Punjabi': 'latest punjabi songs',
    'Bhojpuri': 'latest bhojpuri songs',
    'Tamil': 'latest tamil songs',
    'Telugu': 'latest telugu songs',
    'Marathi': 'latest marathi songs',
    'Bengali': 'latest bengali songs',
    'Gujarati': 'latest gujarati songs',
    'Kannada': 'latest kannada songs',
    'Malayalam': 'latest malayalam songs',
    'Haryanvi': 'latest haryanvi songs',
  };

  /// Songs for one home-screen language row.
  static Future<List<Song>> fetchByLanguage(String language, {int limit = 25}) {
    final phrase = homeLanguages[language] ?? 'latest $language songs';
    return searchLiveSongs(phrase, limit: limit);
  }

  /// Only songs released this year (or last year if there are too few).
  static Future<List<Song>> fetchNewReleases({int limit = 30}) async {
    final year = DateTime.now().year;
    final queries = <String>[
      'new songs $year',
      'new hindi songs $year',
      'new punjabi songs $year',
      'new english songs $year',
      'new bhojpuri songs $year',
    ];
    final lists = await Future.wait(
      queries.map(
        (q) => searchLiveSongs(q, limit: 25).catchError((_) => <Song>[]),
      ),
    );
    return ReleaseFilter.pickNewReleases(
      lists.expand((e) => e).toList(),
      year: year,
      maxItems: limit,
    );
  }

  /// iTunes fallback
  static Future<List<Song>> searchOnlineSongsFallback(
    String query, {
    int limit = 25,
  }) {
    return ITunesSearchService.searchOnlineSongsFallback(query, limit: limit);
  }

  /// Discovers 50-60 related, strictly era-pure and language-pure songs matching the seed song's
  /// era, language, artist, and mood for uninterrupted "Continue Playing".
  static Future<List<Song>> fetchSmartRecommendations(
    Song seedSong, {
    int limit = 55,
  }) async {
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
    final is90s =
        songLanguage == 'Hindi' && !is70s && !is80s && is90sMelodyEra(seedSong);
    final is2000s =
        songLanguage == 'Hindi' &&
        !is70s &&
        !is80s &&
        !is90s &&
        is2000sSong(seedSong);
    final is2010s =
        songLanguage == 'Hindi' &&
        !is70s &&
        !is80s &&
        !is90s &&
        !is2000s &&
        is2010sSong(seedSong);
    final isIndie =
        songLanguage == 'Hindi' &&
        !is70s &&
        !is80s &&
        !is90s &&
        !is2000s &&
        !is2010s &&
        isIndieOrSukoonSong(seedSong);

    final List<Future<List<Song>>> futures = [];

    // 1. Artist-specific query tailored by era
    if (rawArtist.isNotEmpty &&
        rawArtist.toLowerCase() != 'unknown artist' &&
        rawArtist.toLowerCase() != 'music') {
      if (is70s) {
        futures.add(
          searchLiveSongs(
            '$rawArtist 60s 70s golden hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else if (is80s) {
        futures.add(
          searchLiveSongs(
            '$rawArtist 80s disco romantic hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else if (is90s) {
        futures.add(
          searchLiveSongs(
            '$rawArtist 90s romantic melodies',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else if (is2000s) {
        futures.add(
          searchLiveSongs(
            '$rawArtist 2000s romantic hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else if (is2010s) {
        futures.add(
          searchLiveSongs(
            '$rawArtist romantic hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else if (songLanguage == 'English') {
        futures.add(
          searchLiveSongs(
            '$rawArtist English pop indie acoustic hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else if (songLanguage == 'Punjabi') {
        futures.add(
          searchLiveSongs(
            '$rawArtist Punjabi hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else if (songLanguage == 'South') {
        futures.add(
          searchLiveSongs(
            '$rawArtist South hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else {
        futures.add(
          searchLiveSongs(
            '$rawArtist hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      }
    }

    // 2. Language & Era Specific Recommendations
    if (songLanguage == 'Punjabi') {
      futures.add(
        searchLiveSongs(
          'Karan Aujla New Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Diljit Dosanjh Superhits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'AP Dhillon Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Sidhu Moosewala Superhits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Top Punjabi Chartbusters 2024',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (songLanguage == 'South') {
      futures.add(
        searchLiveSongs(
          'Anirudh Ravichander Tamil Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Sid Sriram Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Top Tamil Superhits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Telugu Chartbusters',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (songLanguage == 'English') {
      futures.add(
        searchLiveSongs(
          'Billboard Hot 100 English Pop Hits',
          limit: 20,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Global English Superhits Chart',
          limit: 20,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Acoustic English Indie Melodies',
          limit: 20,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Best of Indie English acoustic',
          limit: 20,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Global Acoustic Pop English Hits',
          limit: 20,
        ).catchError((_) => <Song>[]),
      );
    } else if (songLanguage == 'Bhojpuri') {
      futures.add(
        searchLiveSongs(
          'Pawan Singh Bhojpuri Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Khesari Lal Superhits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (songLanguage == 'Haryanvi') {
      futures.add(
        searchLiveSongs(
          'Gulzaar Chhaniwala Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Top Haryanvi Chartbusters',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (is70s) {
      futures.add(
        searchLiveSongs(
          'Kishore Kumar 70s Evergreen Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Lata Mangeshkar 60s 70s Golden Era Classics',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Mohammed Rafi 60s 70s Classic Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Mukesh Golden Era Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'RD Burman SD Burman 60s 70s Superhits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Vintage Bollywood Golden Classics 60s 70s',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (is80s) {
      futures.add(
        searchLiveSongs(
          '80s Bollywood Disco Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Bappi Lahiri 80s Superhits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          '80s Bollywood Romantic Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Amit Kumar 80s Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Chandni Tezaab QSQT 80s Songs',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (is90s) {
      futures.add(
        searchLiveSongs(
          'Kumar Sanu Alka Yagnik 90s Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Udit Narayan 90s Evergreen Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Nadeem Shravan 90s Magic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          '90s Bollywood Evergreen Romantic Songs',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(fetch90sDuets().catchError((_) => <Song>[]));
    } else if (is2000s) {
      futures.add(
        searchLiveSongs(
          '2000s Bollywood Romantic Nostalgia',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'KK Best Soulful Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Atif Aslam 2000s Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Mohit Chauhan 2000s Soulful Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Emraan Hashmi Era Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (is2010s) {
      futures.add(
        searchLiveSongs(
          'Arijit Singh 2010s Romantic Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Aashiqui 2 Kabir Singh Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          '2010s Bollywood Superhit Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Armaan Malik Jubin Nautiyal Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
    } else if (isIndie) {
      futures.add(
        searchLiveSongs(
          'Indie India Sukoon Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Anuv Jain Prateek Kuhad Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Acoustic Hindi Sukoon Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(fetchBestOfIndie().catchError((_) => <Song>[]));
    } else {
      futures.add(
        searchLiveSongs(
          'Darshan Raval Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Arijit Singh Modern Romantic Hits',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
      futures.add(
        searchLiveSongs(
          'Trending Bollywood Romantic Melodies',
          limit: 15,
        ).catchError((_) => <Song>[]),
      );
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
              if (!isVintageGoldenEra(song) ||
                  is80sEra(song) ||
                  is90sMelodyEra(song) ||
                  is2000sSong(song) ||
                  is2010sSong(song)) {
                continue;
              }
            } else if (is80s) {
              if (isVintageGoldenEra(song) ||
                  is90sMelodyEra(song) ||
                  is2000sSong(song) ||
                  is2010sSong(song)) {
                continue;
              }
            } else if (is90s) {
              if (isVintageGoldenEra(song) ||
                  is80sEra(song) ||
                  is2000sSong(song) ||
                  is2010sSong(song)) {
                continue;
              }
            } else if (is2000s) {
              if (isVintageGoldenEra(song) ||
                  is80sEra(song) ||
                  is90sMelodyEra(song) ||
                  is2010sSong(song)) {
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
