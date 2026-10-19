import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../config/app_config.dart';
import 'api/song_parser_utils.dart';
import 'gemini_ai_service.dart';

/// Lyrics Service responsible for fetching, caching, and parsing synced (LRC) & plain lyrics
class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  static LyricsService get instance => _instance;

  LyricsService._internal();

  final Map<String, String> _cache = {};

  /// Custom HTTP client for hermetic unit testing
  @visibleForTesting
  static http.Client? mockHttpClient;

  http.Client get _client => mockHttpClient ?? http.Client();

  /// Expose immutable view of cache for diagnostics/testing
  Map<String, String> get cache => Map.unmodifiable(_cache);

  /// Alias for [getLyrics] to fetch lyrics for a [song]
  Future<String?> fetch(Song song, {bool forceRefresh = false}) =>
      getLyrics(song, forceRefresh: forceRefresh);

  /// Retrieves lyrics for a [song]. Checks in-memory cache first, then song's embedded
  /// lyrics, then attempts multi-tier external lookup via LRCLIB, JioSaavn, and Gemini AI.
  Future<String?> getLyrics(Song song, {bool forceRefresh = false}) async {
    final cacheKey = _buildCacheKey(song.id, song.title, song.artist);
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 1. Use embedded lyrics if available
    if (song.lyrics.trim().isNotEmpty) {
      _cache[cacheKey] = song.lyrics.trim();
      return _cache[cacheKey];
    }

    // 2. Fetch from online lyrics provider (LRCLIB with multi-tier fallbacks, JioSaavn & Gemini)
    final fetched = await fetchLyricsByQuery(
      title: song.title,
      artist: song.artist,
      durationSeconds: song.duration.inSeconds > 0
          ? song.duration.inSeconds
          : null,
      songId: song.id,
    );

    if (fetched != null && fetched.trim().isNotEmpty) {
      _cache[cacheKey] = fetched.trim();
      return _cache[cacheKey];
    }

    return null;
  }

  /// Multi-tier search for synchronized or plain lyrics:
  /// Tier 1-4: LRCLIB with multiple artist candidate variations and strict title matching
  /// Tier 5: JioSaavn official lyrics API
  /// Tier 6: Gemini AI lyrics generation
  Future<String?> fetchLyricsByQuery({
    required String title,
    required String artist,
    int? durationSeconds,
    String? songId,
  }) async {
    final cleanTitle = _cleanSongTitle(title);
    if (cleanTitle.isEmpty) return null;

    final artistCandidates = _getArtistCandidates(artist);
    const headers = {'User-Agent': 'JumboMusic/2.0.0 (https://jumbomusic.app)'};

    // -------------------------------------------------------------
    // Tier 1 & 2: LRCLIB Exact GET for each candidate (duration & no-duration)
    // -------------------------------------------------------------
    for (final cand in artistCandidates) {
      // Tier 1: With duration
      if (durationSeconds != null && durationSeconds > 0) {
        try {
          final uri1 = Uri.https('lrclib.net', '/api/get', {
            'track_name': cleanTitle,
            if (cand.isNotEmpty) 'artist_name': cand,
            'duration': durationSeconds.toString(),
          });
          final res1 = await _client
              .get(uri1, headers: headers)
              .timeout(const Duration(seconds: 4));
          if (res1.statusCode == 200) {
            final data = jsonDecode(utf8.decode(res1.bodyBytes));
            if (_isValidMatch(data, cleanTitle, durationSeconds)) {
              final lrc = _extractLrc(data);
              if (lrc != null) return lrc;
            }
          }
        } catch (_) {}
      }

      // Tier 2: Without duration
      try {
        final uri2 = Uri.https('lrclib.net', '/api/get', {
          'track_name': cleanTitle,
          if (cand.isNotEmpty) 'artist_name': cand,
        });
        final res2 = await _client
            .get(uri2, headers: headers)
            .timeout(const Duration(seconds: 4));
        if (res2.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res2.bodyBytes));
          if (_isValidMatch(data, cleanTitle, durationSeconds)) {
            final lrc = _extractLrc(data);
            if (lrc != null) return lrc;
          }
        }
      } catch (_) {}
    }

    // -------------------------------------------------------------
    // Tier 3: LRCLIB Search with title + primary artist
    // -------------------------------------------------------------
    for (final cand in artistCandidates) {
      if (cand.isEmpty) continue;
      try {
        final uri3 = Uri.https('lrclib.net', '/api/search', {
          'q': '$cleanTitle $cand',
        });
        final res3 = await _client
            .get(uri3, headers: headers)
            .timeout(const Duration(seconds: 5));
        if (res3.statusCode == 200) {
          final list = jsonDecode(utf8.decode(res3.bodyBytes));
          if (list is List && list.isNotEmpty) {
            for (final item in list) {
              if (item is Map<String, dynamic> &&
                  _isValidMatch(item, cleanTitle, durationSeconds)) {
                final lrc = _extractLrc(item);
                if (lrc != null) return lrc;
              }
            }
          }
        }
      } catch (_) {}
    }

    // -------------------------------------------------------------
    // Tier 4: LRCLIB Search with title only (strict match)
    // -------------------------------------------------------------
    try {
      final uri4 = Uri.https('lrclib.net', '/api/search', {
        'track_name': cleanTitle,
      });
      final res4 = await _client
          .get(uri4, headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res4.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res4.bodyBytes));
        if (list is List && list.isNotEmpty) {
          for (final item in list) {
            if (item is Map<String, dynamic> &&
                _isValidMatch(item, cleanTitle, durationSeconds)) {
              final lrc = _extractLrc(item);
              if (lrc != null) return lrc;
            }
          }
        }
      }
    } catch (_) {}

    // -------------------------------------------------------------
    // Tier 5: JioSaavn Official Lyrics Fallback (100% accurate for Indian & Bollywood)
    // -------------------------------------------------------------
    try {
      final jioSaavnLyrics = await _fetchJioSaavnLyrics(
        songId,
        cleanTitle,
        artist,
      );
      if (jioSaavnLyrics != null && jioSaavnLyrics.isNotEmpty) {
        return jioSaavnLyrics;
      }
    } catch (_) {}

    // -------------------------------------------------------------
    // Tier 6: Gemini AI Fallback (if key is configured)
    // -------------------------------------------------------------
    if (AppConfig.geminiApiKey.isNotEmpty) {
      try {
        final geminiLyrics = await GeminiAiService.instance.generateLyrics(
          title: cleanTitle,
          artist: artist,
        );
        if (geminiLyrics != null && geminiLyrics.isNotEmpty) {
          return geminiLyrics;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Fetches official lyrics from JioSaavn by song ID or search lookup
  Future<String?> _fetchJioSaavnLyrics(
    String? songId,
    String cleanTitle,
    String artist,
  ) async {
    // 1. Direct song ID lookup if available and not a dummy/temporary ID
    if (songId != null &&
        songId.isNotEmpty &&
        !songId.startsWith('song_') &&
        !songId.startsWith('track_')) {
      try {
        final uri = Uri.https('www.jiosaavn.com', '/api.php', {
          '__call': 'lyrics.getLyrics',
          'lyrics_id': songId,
          'ctx': 'web6dot0',
          'api_version': '4',
          '_format': 'json',
          '_marker': '0',
        });
        final res = await _client.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data is Map && data['lyrics'] is String) {
            final cleaned = _cleanHtmlLyrics(data['lyrics'] as String);
            if (cleaned.isNotEmpty) return cleaned;
          }
        }
      } catch (_) {}
    }

    // 2. Search JioSaavn to find matching song ID
    try {
      final query = artist.isNotEmpty ? '$cleanTitle $artist' : cleanTitle;
      final searchUri = Uri.https('www.jiosaavn.com', '/api.php', {
        '__call': 'search.getResults',
        'q': query,
        'ctx': 'web6dot0',
        'api_version': '4',
        '_format': 'json',
        '_marker': '0',
      });
      final searchRes = await _client
          .get(searchUri)
          .timeout(const Duration(seconds: 4));
      if (searchRes.statusCode == 200) {
        final data = jsonDecode(utf8.decode(searchRes.bodyBytes));
        if (data is Map && data['results'] is List) {
          final results = data['results'] as List;
          for (final item in results) {
            if (item is Map) {
              final trackTitle = item['title']?.toString() ?? '';
              final id = item['id']?.toString() ?? '';
              if (id.isNotEmpty && _isTitleMatching(trackTitle, cleanTitle)) {
                // Found matched track on JioSaavn, fetch its lyrics
                final lyricsUri = Uri.https('www.jiosaavn.com', '/api.php', {
                  '__call': 'lyrics.getLyrics',
                  'lyrics_id': id,
                  'ctx': 'web6dot0',
                  'api_version': '4',
                  '_format': 'json',
                  '_marker': '0',
                });
                final lrcRes = await _client
                    .get(lyricsUri)
                    .timeout(const Duration(seconds: 4));
                if (lrcRes.statusCode == 200) {
                  final lrcData = jsonDecode(utf8.decode(lrcRes.bodyBytes));
                  if (lrcData is Map && lrcData['lyrics'] is String) {
                    final cleaned = _cleanHtmlLyrics(
                      lrcData['lyrics'] as String,
                    );
                    if (cleaned.isNotEmpty) return cleaned;
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Extracts LRC text from LRCLIB response
  String? _extractLrc(dynamic data) {
    if (data is! Map) return null;
    final synced = data['syncedLyrics'] as String?;
    if (synced != null && synced.trim().isNotEmpty) {
      return synced.trim();
    }
    final plain = data['plainLyrics'] as String?;
    if (plain != null && plain.trim().isNotEmpty) {
      return plain.trim();
    }
    return null;
  }

  /// Strict validation to prevent picking wrong songs, instrumental tracks, or remixes of different songs
  bool _isValidMatch(dynamic data, String expectedTitle, int? durationSeconds) {
    if (data is! Map) return false;
    if (data['instrumental'] == true) return false;

    final trackName = (data['trackName'] ?? data['name'])?.toString() ?? '';
    if (trackName.isEmpty) return false;

    if (!_isTitleMatching(trackName, expectedTitle)) {
      return false;
    }

    // If duration is provided and item has duration, check tolerance within 35 seconds
    if (durationSeconds != null && durationSeconds > 0) {
      final itemDur = (data['duration'] as num?)?.toInt() ?? 0;
      if (itemDur > 0 && (itemDur - durationSeconds).abs() > 35) {
        return false;
      }
    }

    return true;
  }

  /// Compares candidate track title against target title with normalization
  bool _isTitleMatching(String resultTitle, String expectedTitle) {
    final normExpected = SongParserUtils.normalizeSongTitle(expectedTitle);
    final normResult = SongParserUtils.normalizeSongTitle(resultTitle);

    if (normExpected.isEmpty || normResult.isEmpty) return false;
    if (normExpected == normResult) return true;

    // Check prefix / token match
    if (normResult.startsWith('$normExpected ') ||
        normExpected.startsWith('$normResult ')) {
      return true;
    }

    // Do not match if the titles are clearly different songs (e.g. Pachtaoge vs Tum Hi Ho)
    return false;
  }

  /// Extracts multiple candidate artist variations from an artist string
  /// In Bollywood and Indian regional music, the music director is often listed first
  /// followed by the vocalist (e.g. "Mithoon, Arijit Singh").
  List<String> _getArtistCandidates(String artist) {
    final clean = artist.trim();
    if (clean.isEmpty) return const [''];

    final candidates = <String>[];

    // Split on commas, ampersands, slashes, and feat/ft
    final parts = clean
        .split(
          RegExp(
            r'[,/&]|(?:\s+feat\.?\s+)|(?:\s+ft\.?\s+)',
            caseSensitive: false,
          ),
        )
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // If there are multiple artists, try individual artists
    // In Bollywood, the 2nd artist is very often the singer who holds the lyric credits
    if (parts.length > 1) {
      for (final p in parts.reversed) {
        if (!candidates.contains(p)) candidates.add(p);
      }
    }

    for (final p in parts) {
      if (!candidates.contains(p)) candidates.add(p);
    }

    // Also include the full combined artist name
    if (!candidates.contains(clean)) {
      candidates.add(clean);
    }

    return candidates;
  }

  /// Cleans HTML tags and unescapes entities from lyrics
  String _cleanHtmlLyrics(String html) {
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    return SongParserUtils.unescape(text);
  }

  /// Manually cache lyrics for a song
  void cacheLyrics(
    String songId,
    String lyrics, {
    String title = '',
    String artist = '',
  }) {
    final key = _buildCacheKey(songId, title, artist);
    _cache[key] = lyrics.trim();
  }

  /// Check if a lyrics string has valid synchronized timestamps
  bool isSynced(String? lyrics) {
    if (lyrics == null || lyrics.trim().isEmpty) return false;
    return RegExp(r'\[\d{1,2}:\d{2}(?:\.\d{1,3})?\]').hasMatch(lyrics);
  }

  /// Clear in-memory lyrics cache
  void clearCache() {
    _cache.clear();
  }

  String _buildCacheKey(String id, String title, String artist) {
    if (id.isNotEmpty) return id;
    return '${title.trim().toLowerCase()}_${artist.trim().toLowerCase()}';
  }

  String _cleanSongTitle(String title) {
    return title
        .replaceAll(
          RegExp(
            r'\(.*?(remix|official|video|audio|lyrics|from|version).*?\)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'-.*?from.*', caseSensitive: false), '')
        .trim();
  }
}
