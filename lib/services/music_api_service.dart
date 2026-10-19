import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../config/app_config.dart';
import 'release_filter.dart';
import 'api/song_parser_utils.dart';
import 'api/music_tag_classifier.dart';
import 'api/itunes_search_service.dart';
import 'api/jamendo_search_service.dart';
import 'crash_reporting_service.dart';

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
  static MusicEra detectSongEra(Song song) =>
      MusicTagClassifier.detectSongEra(song);
  static bool isGenZModern(Song song) => MusicTagClassifier.isGenZModern(song);
  static bool isEnglishSong(Song song) =>
      MusicTagClassifier.isEnglishSong(song);

  @visibleForTesting
  static Future<List<Song>> Function(String query, {int limit})?
  mockSearchLiveSongs;

  /// Live Search matching aura-stream-henna.vercel.app
  static Future<List<Song>> searchLiveSongs(
    String query, {
    int limit = 30,
  }) async {
    if (mockSearchLiveSongs != null) {
      return mockSearchLiveSongs!(query, limit: limit);
    }
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // When unofficial catalog is disabled, use ONLY Jamendo and never Supabase or iTunes
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search(cleanQuery, limit: limit);
    }

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
            if (song != null && song.duration.inSeconds >= 75) {
              songs.add(song);
            }
          }
        }
        if (songs.isNotEmpty) return songs;
      }

      // If initial search with raw title returned empty, retry with normalized title
      final normalizedQuery = SongParserUtils.normalizeSongTitle(cleanQuery);
      if (normalizedQuery.isNotEmpty &&
          normalizedQuery != cleanQuery.toLowerCase()) {
        final normUri = Uri.parse(
          '$_endpoint?action=jiosaavn-search&q=${Uri.encodeComponent(normalizedQuery)}&limit=$limit',
        );
        final normResponse = await http
            .get(normUri, headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (normResponse.statusCode == 200) {
          final data = jsonDecode(normResponse.body) as Map<String, dynamic>;
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
              if (song != null && song.duration.inSeconds >= 75) {
                songs.add(song);
              }
            }
          }
          if (songs.isNotEmpty) return songs;
        }
      }
    } catch (error) {
      // Fallback below
      CrashReportingService.swallow(error, 'music_api_service.dart:81');
    }

    // Fallback 1: Jamendo (legal, full-length tracks) when configured
    final jamendo = await JamendoSearchService.search(cleanQuery, limit: limit);
    if (jamendo.isNotEmpty) {
      final fullJamendo = jamendo
          .where((s) => s.duration.inSeconds >= 60)
          .toList();
      if (fullJamendo.isNotEmpty) return fullJamendo;
    }

    // Fallback 2: iTunes live search
    return searchOnlineSongsFallback(cleanQuery, limit: limit);
  }

  /// Fetch playlist songs by ID
  static Future<Map<String, dynamic>> fetchPlaylist(String playlistId) async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return {
        'id': playlistId,
        'name': 'Playlist',
        'coverUrl': '',
        'songs': <Song>[],
      };
    }

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
    } catch (error) {
      CrashReportingService.swallow(error, 'music_api_service.dart:128');
    }
    return {
      'id': playlistId,
      'name': 'Playlist',
      'coverUrl': '',
      'songs': <Song>[],
    };
  }

  /// Curated featured playlists identical to Aura Stream
  static Future<List<Song>> fetchIndiaTop50() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('top hits', limit: 25);
    }
    final result = await fetchPlaylist('1134543272');
    return (result['songs'] as List<Song>?) ?? [];
  }

  static Future<List<Song>> fetchTrendingToday() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('trending', limit: 25);
    }
    final result = await fetchPlaylist('110858205');
    return (result['songs'] as List<Song>?) ?? [];
  }

  static Future<List<Song>> fetchBestOfIndie() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('indie', limit: 25);
    }
    final result = await fetchPlaylist('82914609');
    return (result['songs'] as List<Song>?) ?? [];
  }

  static Future<List<Song>> fetch90sDuets() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('acoustic duet', limit: 25);
    }
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
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search(query, limit: limit);
    }
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
    final Set<String> seenKeys = {
      SongParserUtils.songDeduplicationKey(seedSong),
    };

    final rawArtist = seedSong.artist
        .split(',')
        .first
        .split('&')
        .first
        .split('feat.')
        .first
        .trim();

    final songLanguage = detectSongLanguage(seedSong);
    final songEra = detectSongEra(seedSong);

    final List<Future<List<Song>>> futures = [];

    // 1. Artist-specific query tailored by era
    if (rawArtist.isNotEmpty &&
        rawArtist.toLowerCase() != 'unknown artist' &&
        rawArtist.toLowerCase() != 'music') {
      switch (songEra) {
        case MusicEra.vintage70s:
          futures.add(
            searchLiveSongs(
              '$rawArtist 60s 70s golden hits',
              limit: 15,
            ).catchError((_) => <Song>[]),
          );
          break;
        case MusicEra.era80s:
          futures.add(
            searchLiveSongs(
              '$rawArtist 80s disco romantic hits',
              limit: 15,
            ).catchError((_) => <Song>[]),
          );
          break;
        case MusicEra.era90s:
          futures.add(
            searchLiveSongs(
              '$rawArtist 90s romantic melodies',
              limit: 15,
            ).catchError((_) => <Song>[]),
          );
          break;
        case MusicEra.era2000s:
          futures.add(
            searchLiveSongs(
              '$rawArtist 2000s romantic hits',
              limit: 15,
            ).catchError((_) => <Song>[]),
          );
          break;
        case MusicEra.era2010s:
          futures.add(
            searchLiveSongs(
              '$rawArtist 2010s romantic hits',
              limit: 15,
            ).catchError((_) => <Song>[]),
          );
          break;
        case MusicEra.genZModern:
          if (songLanguage == 'English') {
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
          } else {
            futures.add(
              searchLiveSongs(
                '$rawArtist modern hits',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
          }
          break;
      }
    }

    // 2. Language & Era Specific Recommendations
    if (songLanguage == 'Punjabi') {
      if (songEra == MusicEra.vintage70s ||
          songEra == MusicEra.era80s ||
          songEra == MusicEra.era90s) {
        futures.add(
          searchLiveSongs(
            'Gurdas Maan Evergreen Classic Hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
        futures.add(
          searchLiveSongs(
            'Surinder Kaur Folk Classics',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
        futures.add(
          searchLiveSongs(
            'Kuldeep Manak Hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else {
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
            'Shubh Punjabi Hits',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      }
    } else if (songLanguage == 'South') {
      if (songEra == MusicEra.vintage70s ||
          songEra == MusicEra.era80s ||
          songEra == MusicEra.era90s) {
        futures.add(
          searchLiveSongs(
            'SPB Evergreen Melodies',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
        futures.add(
          searchLiveSongs(
            'Ilaiyaraaja Golden Classics',
            limit: 15,
          ).catchError((_) => <Song>[]),
        );
      } else {
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
      }
    } else if (songLanguage == 'English') {
      switch (songEra) {
        case MusicEra.vintage70s:
          futures.add(
            searchLiveSongs(
              '70s Classic Rock Pop Golden Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Queen Beatles Elton John 70s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              '70s English Folk Pop Melodies',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          break;

        case MusicEra.era80s:
          futures.add(
            searchLiveSongs(
              '80s Synth Pop Rock Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Michael Jackson Madonna 80s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              '80s Classic Pop Anthems',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          break;

        case MusicEra.era90s:
          futures.add(
            searchLiveSongs(
              '90s English Pop Classics',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Backstreet Boys Britney Spears 90s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              '90s Acoustic Pop Melodies',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          break;

        case MusicEra.era2000s:
          futures.add(
            searchLiveSongs(
              '2000s English Pop Rock Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Coldplay Linkin Park 2000s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Maroon 5 Green Day 2000s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              '2000s Acoustic English Melodies',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          break;

        case MusicEra.era2010s:
          futures.add(
            searchLiveSongs(
              '2010s English Pop Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Ed Sheeran Taylor Swift 2010s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Coldplay Bruno Mars 2010s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              '2010s Acoustic Indie Pop Melodies',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          futures.add(
            searchLiveSongs(
              'Avicii Chainsmokers 2010s Hits',
              limit: 20,
            ).catchError((_) => <Song>[]),
          );
          break;

        case MusicEra.genZModern:
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
          break;
      }
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
    } else {
      // Hindi Era Routing
      switch (songEra) {
        case MusicEra.vintage70s:
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
          break;

        case MusicEra.era80s:
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
          break;

        case MusicEra.era90s:
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
          break;

        case MusicEra.era2000s:
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
          break;

        case MusicEra.era2010s:
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
          futures.add(
            searchLiveSongs(
              'Yeh Jawaani Hai Deewani songs',
              limit: 15,
            ).catchError((_) => <Song>[]),
          );
          break;

        case MusicEra.genZModern:
          if (isIndieOrSukoonSong(seedSong)) {
            futures.add(
              searchLiveSongs(
                'Indie India Sukoon Hits',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
            futures.add(
              searchLiveSongs(
                'Anuv Jain Hindi Melodies',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
            futures.add(
              searchLiveSongs(
                'Mitraz Hindi Indie Melodies',
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
            if (rawArtist.isNotEmpty &&
                rawArtist.toLowerCase() != 'unknown artist') {
              futures.add(
                searchLiveSongs(
                  '$rawArtist Modern Romantic Hits',
                  limit: 15,
                ).catchError((_) => <Song>[]),
              );
            }
            futures.add(
              searchLiveSongs(
                'Trending Viral Hindi Hits',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
            futures.add(
              searchLiveSongs(
                'Darshan Raval Modern Romantic Hits',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
            futures.add(
              searchLiveSongs(
                'Arijit Singh Latest Modern Hits',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
            futures.add(
              searchLiveSongs(
                'Gen Z Trending Bollywood Melodies',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
            futures.add(
              searchLiveSongs(
                'Top Bollywood Romantic Songs',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
            futures.add(
              searchLiveSongs(
                'Viral Hindi Romantic Hits',
                limit: 15,
              ).catchError((_) => <Song>[]),
            );
          }
          break;
      }
    }

    try {
      final results = await Future.wait(futures);
      final seedDedupeKey = SongParserUtils.songDeduplicationKey(seedSong);

      for (final songList in results) {
        for (final song in songList) {
          // 1. Language matching filter
          final candLanguage = detectSongLanguage(song);
          if (candLanguage != songLanguage) {
            continue;
          }

          if (songLanguage == 'English') {
            if (!MusicTagClassifier.isEnglishSong(song)) {
              continue;
            }
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
          } else {
            // For Indian languages, ensure zero English songs leak through
            if (MusicTagClassifier.isEnglishSong(song)) {
              continue;
            }
          }

          // 2. Strict Era matching filter
          final candEra = MusicTagClassifier.detectSongEra(song);
          if (candEra != songEra) {
            continue;
          }

          // 3. Audio quality and duration filter (no previews, min 75s)
          if (song.audioUrl.trim().isEmpty ||
              song.audioUrl.contains('apple.com') ||
              song.audioUrl.contains('mzstatic.com') ||
              song.audioUrl.contains('preview') ||
              (song.duration.inSeconds > 0 && song.duration.inSeconds < 75)) {
            continue;
          }

          // 4. Zero Duplicates filter (canonical identity key)
          final dedupeKey = SongParserUtils.songDeduplicationKey(song);
          if (dedupeKey == seedDedupeKey) {
            continue;
          }

          if (seenIds.add(song.id) && seenKeys.add(dedupeKey)) {
            recommendations.add(song);
          }
        }
      }
    } catch (error) {
      CrashReportingService.swallow(error, 'music_api_service.dart:715');
    }

    return recommendations.take(limit).toList();
  }
}
