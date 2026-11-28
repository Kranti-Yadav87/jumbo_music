import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../config/app_config.dart';
import 'release_filter.dart';
import 'api/song_parser_utils.dart';
import 'api/music_tag_classifier.dart';
import 'api/itunes_search_service.dart';
import 'api/jamendo_search_service.dart';
import 'api/youtube_search_service.dart';
import 'crash_reporting_service.dart';

export 'api/song_parser_utils.dart';
export 'api/music_tag_classifier.dart';
export 'api/itunes_search_service.dart';
export 'api/youtube_search_service.dart';

class MusicApiService {
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

  // In-memory LRU search cache for instant 0ms responses
  static final Map<String, List<Song>> _searchCache = {};
  static const int _maxSearchCacheSize = 60;

  /// Returns cached search results synchronously if available
  static List<Song>? getCachedSearch(String query) {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return null;
    return _searchCache[key];
  }

  static void _cacheSearch(String query, List<Song> results) {
    if (results.isEmpty) return;
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return;
    if (_searchCache.length >= _maxSearchCacheSize) {
      _searchCache.remove(_searchCache.keys.first);
    }
    _searchCache[key] = List.unmodifiable(results);
  }

  /// Live Search matching aura-stream-henna.vercel.app with instant caching
  static Future<List<Song>> searchLiveSongs(
    String query, {
    int limit = 30,
  }) async {
    if (mockSearchLiveSongs != null) {
      return mockSearchLiveSongs!(query, limit: limit);
    }
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Instant return if query is already cached in memory
    final cached = getCachedSearch(cleanQuery);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // When unofficial catalog is disabled, use ONLY Jamendo and never Supabase or iTunes
    if (!AppConfig.isUnofficialCatalogEnabled) {
      final jRes = await JamendoSearchService.search(cleanQuery, limit: limit);
      _cacheSearch(cleanQuery, jRes);
      return jRes;
    }

    // Run JioSaavn and YouTube Music in parallel.
    final searchFutures = await Future.wait([
      _searchJioSaavn(cleanQuery, limit: limit).catchError((error) {
        CrashReportingService.swallow(
          error,
          'music_api_service.dart:jioSearch',
        );
        return <Song>[];
      }),
      YouTubeSearchService.search(cleanQuery, limit: limit).catchError((error) {
        CrashReportingService.swallow(error, 'music_api_service.dart:ytSearch');
        return <Song>[];
      }),
      JamendoSearchService.search(cleanQuery, limit: limit).catchError((error) {
        CrashReportingService.swallow(
          error,
          'music_api_service.dart:jamendoSearch',
        );
        return <Song>[];
      }),
    ]);

    final jioSongs = searchFutures[0];
    final ytSongs = searchFutures[1];
    // Jamendo parser already requires provider duration metadata and rejects
    // explicit preview/promo signals. Do not reject genuine short songs.
    final jamendoSongs = searchFutures[2];

    if (jioSongs.isNotEmpty || ytSongs.isNotEmpty || jamendoSongs.isNotEmpty) {
      final ranked = _rankAndDeduplicateResults(
        cleanQuery,
        jioSongs,
        ytSongs,
        jamendoSongs: jamendoSongs,
        limit: limit,
      );
      if (ranked.isNotEmpty) {
        _cacheSearch(cleanQuery, ranked);
        return ranked;
      }
    }

    // iTunes supplies preview clips, not verified full-track streams.
    // Keep it available only through the explicit fallback API.
    return <Song>[];
  }

  /// JioSaavn search. Web requests use the same-origin Vercel proxy.
  static Uri _jioSaavnSearchUri(String query, int limit) {
    if (kIsWeb) {
      return Uri.base
          .resolve('/api/jiosaavn-search')
          .replace(queryParameters: {'q': query, 'limit': '$limit'});
    }

    return Uri.https('saavn.bycomsolutions.com', '/api/search/songs', {
      'query': query,
      'limit': '$limit',
    });
  }

  static Future<List<Song>> _searchJioSaavn(
    String cleanQuery, {
    int limit = 20,
  }) async {
    Future<List<Song>> fetch(String query) async {
      final response = await http
          .get(
            _jioSaavnSearchUri(query, limit),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 9));

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];

      final innerData = decoded['data'];
      final dynamic rawResults = innerData is Map
          ? innerData['results']
          : decoded['results'];

      if (rawResults is! List) return [];

      final songs = <Song>[];
      for (final item in rawResults) {
        if (item is Map<String, dynamic>) {
          final song = SongParserUtils.parseSong(item);
          // JioSaavn must supply a real positive duration; zero is unknown,
          // not proof that the result is a complete track.
          if (song != null && song.duration.inSeconds > 0) {
            songs.add(song);
          }
        }
      }
      return songs;
    }

    try {
      final songs = await fetch(cleanQuery);
      if (songs.isNotEmpty) return songs;

      final normalizedQuery = SongParserUtils.normalizeSongTitle(cleanQuery);
      if (normalizedQuery.isNotEmpty &&
          normalizedQuery != cleanQuery.toLowerCase()) {
        return await fetch(normalizedQuery);
      }
    } catch (error) {
      CrashReportingService.swallow(
        error,
        'music_api_service.dart:_searchJioSaavn',
      );
    }

    return [];
  }

  /// Test-only entry point for the real shared search ranking implementation.
  @visibleForTesting
  static List<Song> rankSearchResultsForTesting(
    String query,
    List<Song> jioSongs,
    List<Song> ytSongs, {
    List<Song> jamendoSongs = const [],
    int limit = 30,
  }) {
    return _rankAndDeduplicateResults(
      query,
      jioSongs,
      ytSongs,
      jamendoSongs: jamendoSongs,
      limit: limit,
    );
  }

  /// Ranks merged provider results by title and artist relevance.
  static List<Song> _rankAndDeduplicateResults(
    String query,
    List<Song> jioSongs,
    List<Song> ytSongs, {
    List<Song> jamendoSongs = const [],
    int limit = 30,
  }) {
    if (limit <= 0 ||
        (jioSongs.isEmpty && ytSongs.isEmpty && jamendoSongs.isEmpty)) {
      return [];
    }

    final allCandidates = [...ytSongs, ...jioSongs, ...jamendoSongs];
    final normalizedQuery = SongParserUtils.normalizeSongTitle(query);
    final queryLower = normalizedQuery.toLowerCase();

    const stopWords = {
      'by',
      'song',
      'songs',
      'track',
      'audio',
      'video',
      'official',
      'full',
      'mp3',
      'feat',
      'ft',
      'the',
      'a',
      'an',
      'of',
      'in',
      'on',
      'new',
      'latest',
      'ka',
      'ki',
      'ke',
      'ko',
      'se',
      'me',
      'mein',
      'with',
    };

    final rawTokens = queryLower
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList();

    final searchTokens = rawTokens
        .where((token) => !stopWords.contains(token))
        .toSet()
        .toList();

    final byMatch = RegExp(
      r'\s+by\s+',
      caseSensitive: false,
    ).firstMatch(query.trim());

    final titleIntent = byMatch == null
        ? ''
        : SongParserUtils.normalizeSongTitle(
            query.trim().substring(0, byMatch.start),
          );

    final artistIntent = byMatch == null
        ? ''
        : SongParserUtils.normalizeSongTitle(
            query.trim().substring(byMatch.end),
          );

    bool containsWholeWord(String text, String token) {
      final words = text
          .split(RegExp(r'[^a-z0-9]+'))
          .where((word) => word.isNotEmpty);
      return words.contains(token);
    }

    double scoreSong(Song song) {
      final title = SongParserUtils.normalizeSongTitle(song.title);
      final artist = SongParserUtils.normalizeSongTitle(song.artist);
      double score = 0;

      // Full title and phrase matches carry strong relevance.
      if (queryLower.isNotEmpty && title == queryLower) {
        score += 200;
      } else if (queryLower.length > 2 && title.contains(queryLower)) {
        score += 110;
      }

      if (queryLower.isNotEmpty && artist == queryLower) {
        score += 100;
      }

      final normalizedUploader = SongParserUtils.normalizeSongTitle(
        song.uploaderName,
      );
      final hasUnknownArtist = artist.isEmpty || artist == 'unknown artist';

      int matchedTokens = 0;
      for (final token in searchTokens) {
        final titleMatch = containsWholeWord(title, token);
        final artistMatch = containsWholeWord(artist, token);
        final uploaderMatch =
            hasUnknownArtist &&
            searchTokens.length > 1 &&
            !titleMatch &&
            containsWholeWord(normalizedUploader, token);

        if (titleMatch) {
          score += 30;
          if (title.startsWith(token)) score += 8;
        }

        if (artistMatch) {
          score += 48;
        }

        if (uploaderMatch) {
          score += 32;
        }

        if (titleMatch || artistMatch || uploaderMatch) matchedTokens++;
      }

      // Reward candidates that cover the complete meaningful query.
      if (searchTokens.isNotEmpty && matchedTokens == searchTokens.length) {
        score += 110;
      } else if (searchTokens.length > 1 && matchedTokens >= 2) {
        score += 25;
      }

      // When the user explicitly types "title by artist", evaluate both
      // parts separately. Keep title-only candidates as lower-ranked fallbacks.
      if (titleIntent.isNotEmpty && artistIntent.isNotEmpty) {
        if (title == titleIntent) {
          score += 100;
        } else if (title.contains(titleIntent)) {
          score += 60;
        }

        if (artist == artistIntent) {
          score += 180;
        } else if (artist.contains(artistIntent)) {
          score += 150;
        } else if (title == titleIntent) {
          score -= 35;
        }

        // Uploader is only a weak fallback when the actual artist is unknown.

        final uploaderMatchesArtist = RegExp(
          r'(^|[^a-z0-9])' + RegExp.escape(artistIntent) + r'([^a-z0-9]|$)',
        ).hasMatch(normalizedUploader);

        if (hasUnknownArtist && uploaderMatchesArtist) {
          if (normalizedUploader == artistIntent) {
            score += 45;
          } else {
            score += 25;
          }
        }
      }

      // Smart Music: capped popularity bonus.
      final views = song.viewCount < 0 ? 0 : song.viewCount;
      final likes = song.likeCount < 0 ? 0 : song.likeCount;

      if (views > 0) {
        score += (math.log(views + 1) / math.ln10 * 3).clamp(0.0, 20.0);
      }
      if (likes > 0) {
        score += (math.log(likes + 1) / math.ln10 * 0.5).clamp(0.0, 3.0);
      }

      final titleAndTagsText = [
        song.title,
        ...song.tags,
      ].join(' ').toLowerCase();

      final descriptionText = song.description.toLowerCase();
      final combinedMetadata = '$titleAndTagsText $descriptionText';

      // Official wording is a weak signal, not proof of authenticity.
      if (RegExp(
        r'\bofficial\s+(audio|music video|video)\b',
      ).hasMatch(combinedMetadata)) {
        score += 8;
      }

      if (song.categoryId == '10') score += 2;

      // Strong indicators in title/tags.
      if (RegExp(r'\bkaraoke\b').hasMatch(titleAndTagsText)) {
        score -= 55;
      }
      if (RegExp(r'\bcover\b').hasMatch(titleAndTagsText)) {
        score -= 45;
      }
      if (RegExp(r'\bfan[ -]?made\b').hasMatch(titleAndTagsText)) {
        score -= 45;
      }
      if (RegExp(r'\breaction\b').hasMatch(titleAndTagsText)) {
        score -= 55;
      }
      if (RegExp(r'\bshorts?\b|#shorts').hasMatch(titleAndTagsText)) {
        score -= 25;
      }

      // Description penalties require explicit context.
      if (RegExp(
        r'\bkaraoke\s+(version|track|instrumental)\b',
      ).hasMatch(descriptionText)) {
        score -= 55;
      }
      final hasExplicitDescriptionCover =
          RegExp(
            r'\bcover\s+(version|song|of|for)\b',
          ).hasMatch(descriptionText) &&
          !RegExp(
            r'\b(not|no|never|isn.t|is not)\s+(a\s+)?cover\b',
          ).hasMatch(descriptionText) &&
          !RegExp(
            r'\bcover\s+art\b|\bcover\s+photo\b',
          ).hasMatch(descriptionText);

      if (hasExplicitDescriptionCover) {
        score -= 45;
      }
      if (RegExp(r'\bfan[ -]?made\b').hasMatch(descriptionText)) {
        score -= 45;
      }
      if (RegExp(
        r'\breaction\s+video\b|\breacts?\s+to\b',
      ).hasMatch(descriptionText)) {
        score -= 55;
      }
      if (RegExp(r'#shorts\b|\byoutube\s+shorts\b').hasMatch(descriptionText)) {
        score -= 25;
      }

      // Prefer common full-song duration without rejecting short originals.
      final durationSeconds = song.duration.inSeconds;
      if (durationSeconds >= 120 && durationSeconds <= 480) {
        score += 3;
      } else if (durationSeconds > 600) {
        score -= 3;
      } else if (durationSeconds > 0 && durationSeconds < 60) {
        score -= 4;
      } else if (durationSeconds >= 60 && durationSeconds < 120) {
        score -= 2;
      }

      // Preserve the existing provider tie-breaker.
      if (!song.id.startsWith('yt_') &&
          song.audioUrl.isNotEmpty &&
          !song.audioUrl.contains('youtube.com')) {
        score += 5;
      }
      return score;
    }

    // Preserve provider order when two candidates have equal scores.

    // Exclude clearly non-original or low-quality YouTube uploads.
    // Keep JioSaavn and Jamendo catalog results unaffected.
    bool shouldExcludeYouTubeCandidate(Song song) {
      if (!song.id.startsWith('yt_')) return false;

      final titleAndTags = [song.title, ...song.tags].join(' ').toLowerCase();

      final description = song.description.toLowerCase();

      // "Cover art" is artwork metadata, not a cover-song indicator.
      final titleMetadata = titleAndTags.replaceAll(
        RegExp(r'\bcover\s+(?:art|photo|image)\b'),
        ' ',
      );

      final hasUnwantedTitleSignal = RegExp(
        r'\b(?:cover|karaoke|lyrics?|fan[\s-]?(?:made|edit)|reaction|shorts?|slowed|reverb|remix)\b',
      ).hasMatch(titleMetadata);

      final hasUnwantedDescriptionSignal = RegExp(
        r'\b(?:karaoke|lyrics?\s+video|fan[\s-]?(?:made|edit)|reaction\s+video|youtube\s+shorts|#shorts|slowed(?:\s+and\s+reverb)?|reverb|remix|cover\s+(?:version|song|of)|(?:my|recorded|sung)\s+cover)\b',
      ).hasMatch(description);

      final hasPreviewOrClipSignal =
          RegExp(
            r'\b(?:preview|sample|snippet|teaser|trailer|promo|clip|shorts?)\b|#shorts',
          ).hasMatch(titleMetadata) ||
          RegExp(
            r'\b(?:preview|sample|snippet|teaser|trailer|promo|clip|youtube\s+shorts)\b|#shorts',
          ).hasMatch(description);

      return hasUnwantedTitleSignal ||
          hasUnwantedDescriptionSignal ||
          hasPreviewOrClipSignal;
    }

    final rankedCandidates = allCandidates.asMap().entries.toList();
    rankedCandidates.sort((a, b) {
      final comparison = scoreSong(b.value).compareTo(scoreSong(a.value));
      return comparison != 0 ? comparison : a.key.compareTo(b.key);
    });

    final seenArtistsByTitle = <String, List<MapEntry<bool, Set<String>>>>{};
    final ranked = <Song>[];

    for (final entry in rankedCandidates) {
      final song = entry.value;
      if (shouldExcludeYouTubeCandidate(song)) continue;
      final cleanTitle = SongParserUtils.normalizeSongTitle(song.title);
      final normalizedArtist = song.artist.trim().toLowerCase();
      final hasUnknownArtist =
          normalizedArtist.isEmpty || normalizedArtist == 'unknown artist';

      final artistParts = hasUnknownArtist
          ? <String>[SongParserUtils.normalizeSongTitle(song.uploaderName)]
          : song.artist
                .split(RegExp(r'[,&/]'))
                .map(SongParserUtils.normalizeSongTitle)
                .where((part) => part.isNotEmpty)
                .toList();

      artistParts.removeWhere((part) => part.isEmpty);
      artistParts.sort();

      // Keep tracks with no artist or uploader metadata distinct.
      final identityParts = artistParts.isNotEmpty
          ? artistParts.toSet()
          : <String>{'unknown:${song.id}'};

      final previousIdentities = cleanTitle.isEmpty
          ? <MapEntry<bool, Set<String>>>[]
          : seenArtistsByTitle.putIfAbsent(
              cleanTitle,
              () => <MapEntry<bool, Set<String>>>[],
            );

      final exactDuplicate = previousIdentities.any(
        (existing) =>
            existing.value.length == identityParts.length &&
            existing.value.containsAll(identityParts),
      );

      // An unknown-artist upload may match one member of a real
      // collaboration. Only apply this fallback across known/unknown
      // artist pairs; never merge two different real collaborations.
      final uploaderCollaborationDuplicate = previousIdentities.any((existing) {
        if (existing.key == hasUnknownArtist) return false;

        final unknownParts = hasUnknownArtist ? identityParts : existing.value;
        final realArtistParts = hasUnknownArtist
            ? existing.value
            : identityParts;

        return unknownParts.length == 1 &&
            realArtistParts.contains(unknownParts.first);
      });

      if (cleanTitle.isNotEmpty &&
          (exactDuplicate || uploaderCollaborationDuplicate)) {
        continue;
      }

      if (cleanTitle.isNotEmpty) {
        previousIdentities.add(MapEntry(hasUnknownArtist, identityParts));
      }

      ranked.add(song);
      if (ranked.length >= limit) break;
    }

    return ranked;
  }

  /// Search YouTube Music directly using the InnerTube API and key
  static Future<List<Song>> searchYouTubeSongs(
    String query, {
    int limit = 20,
  }) async {
    return YouTubeSearchService.search(query, limit: limit);
  }

  /// Fetches a JioSaavn playlist by its original playlist ID.
  static Uri _jioSaavnPlaylistUri(String playlistId) {
    if (kIsWeb) {
      return Uri.base
          .resolve('/api/jiosaavn-playlist')
          .replace(queryParameters: {'id': playlistId});
    }

    return Uri.https('saavn.bycomsolutions.com', '/api/playlists', {
      'id': playlistId,
    });
  }

  static Future<Map<String, dynamic>> fetchPlaylist(String playlistId) async {
    Map<String, dynamic> emptyPlaylist() => {
      'id': playlistId,
      'name': 'Playlist',
      'coverUrl': '',
      'songs': <Song>[],
    };

    if (!AppConfig.isUnofficialCatalogEnabled) {
      return emptyPlaylist();
    }

    try {
      final response = await http
          .get(
            _jioSaavnPlaylistUri(playlistId),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return emptyPlaylist();

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        return emptyPlaylist();
      }

      final pData = decoded['data'];
      if (pData is! Map) return emptyPlaylist();

      final name = SongParserUtils.unescape(
        pData['name'] ?? pData['title'] ?? 'Playlist',
      );
      final coverUrl = SongParserUtils.extractImage(pData['image']);
      final songList = pData['songs'] ?? pData['list'] ?? [];

      final songs = <Song>[];
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
    } catch (error) {
      CrashReportingService.swallow(
        error,
        'music_api_service.dart:fetchPlaylist',
      );
      return emptyPlaylist();
    }
  }

  /// Curated featured sections: original JioSaavn playlists with Jamendo fallback.
  static Future<List<Song>> fetchIndiaTop50() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('top hits', limit: 25);
    }
    final result = await fetchPlaylist('1134543272');
    return (result['songs'] as List<Song>?) ?? <Song>[];
  }

  static Future<List<Song>> fetchTrendingToday() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('trending', limit: 25);
    }
    final result = await fetchPlaylist('110858205');
    return (result['songs'] as List<Song>?) ?? <Song>[];
  }

  static Future<List<Song>> fetchBestOfIndie() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('indie', limit: 25);
    }
    final result = await fetchPlaylist('82914609');
    return (result['songs'] as List<Song>?) ?? <Song>[];
  }

  static Future<List<Song>> fetch90sDuets() async {
    if (!AppConfig.isUnofficialCatalogEnabled) {
      return JamendoSearchService.search('acoustic duet', limit: 25);
    }
    final result = await fetchPlaylist('159470188');
    return (result['songs'] as List<Song>?) ?? <Song>[];
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

          // 3. Reject empty audio URLs and Apple preview audio.
          // Do not reject genuine short songs based on duration alone.
          final audioUrl = song.audioUrl.trim().toLowerCase();
          if (audioUrl.isEmpty ||
              audioUrl.contains('apple.com') ||
              audioUrl.contains('mzstatic.com')) {
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
