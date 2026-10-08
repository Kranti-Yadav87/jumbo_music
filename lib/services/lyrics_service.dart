import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

/// Lyrics Service responsible for fetching, caching, and parsing synced (LRC) & plain lyrics
class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  static LyricsService get instance => _instance;

  LyricsService._internal();

  final Map<String, String> _cache = {};

  /// Expose immutable view of cache for diagnostics/testing
  Map<String, String> get cache => Map.unmodifiable(_cache);

  /// Alias for [getLyrics] to fetch lyrics for a [song]
  Future<String?> fetch(Song song, {bool forceRefresh = false}) =>
      getLyrics(song, forceRefresh: forceRefresh);

  /// Retrieves lyrics for a [song]. Checks in-memory cache first, then song's embedded
  /// lyrics, then attempts multi-tier external lookup via LRCLIB and Supabase.
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

    // 2. Fetch from online lyrics provider (LRCLIB with multi-tier fallbacks)
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

  /// Multi-tier LRCLIB & Supabase search for synchronized or plain lyrics
  Future<String?> fetchLyricsByQuery({
    required String title,
    required String artist,
    int? durationSeconds,
    String? songId,
  }) async {
    final cleanTitle = _cleanSongTitle(title);
    final cleanArtist = _cleanArtistName(artist);
    if (cleanTitle.isEmpty) return null;

    const headers = {'User-Agent': 'JumboMusic/2.0.0 (https://jumbomusic.app)'};

    // Tier 1: Exact GET with duration
    try {
      final uri1 = Uri.https('lrclib.net', '/api/get', {
        'track_name': cleanTitle,
        if (cleanArtist.isNotEmpty) 'artist_name': cleanArtist,
        if (durationSeconds != null && durationSeconds > 0)
          'duration': durationSeconds.toString(),
      });
      final res1 = await http
          .get(uri1, headers: headers)
          .timeout(const Duration(seconds: 4));
      if (res1.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res1.bodyBytes));
        final lrc = _extractLrc(data);
        if (lrc != null) return lrc;
      }
    } catch (_) {}

    // Tier 2: Exact GET without duration (tolerates duration offsets)
    try {
      final uri2 = Uri.https('lrclib.net', '/api/get', {
        'track_name': cleanTitle,
        if (cleanArtist.isNotEmpty) 'artist_name': cleanArtist,
      });
      final res2 = await http
          .get(uri2, headers: headers)
          .timeout(const Duration(seconds: 4));
      if (res2.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res2.bodyBytes));
        final lrc = _extractLrc(data);
        if (lrc != null) return lrc;
      }
    } catch (_) {}

    // Tier 3: Search endpoint with title + artist
    try {
      final query = cleanArtist.isNotEmpty
          ? '$cleanTitle $cleanArtist'
          : cleanTitle;
      final uri3 = Uri.https('lrclib.net', '/api/search', {'q': query});
      final res3 = await http
          .get(uri3, headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res3.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res3.bodyBytes));
        if (list is List && list.isNotEmpty) {
          for (final item in list) {
            final lrc = _extractLrc(item);
            if (lrc != null) return lrc;
          }
        }
      }
    } catch (_) {}

    // Tier 4: Search endpoint with title only
    try {
      final uri4 = Uri.https('lrclib.net', '/api/search', {
        'track_name': cleanTitle,
      });
      final res4 = await http
          .get(uri4, headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res4.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res4.bodyBytes));
        if (list is List && list.isNotEmpty) {
          for (final item in list) {
            final lrc = _extractLrc(item);
            if (lrc != null) return lrc;
          }
        }
      }
    } catch (_) {}

    return null;
  }

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
            r'\(.*?(remix|official|video|audio|lyrics|from).*?\)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'-.*?from.*', caseSensitive: false), '')
        .trim();
  }

  String _cleanArtistName(String artist) {
    if (artist.contains(',')) {
      return artist.split(',').first.trim();
    }
    if (artist.contains('&')) {
      return artist.split('&').first.trim();
    }
    return artist.trim();
  }
}
