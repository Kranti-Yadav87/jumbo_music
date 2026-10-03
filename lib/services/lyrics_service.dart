import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Retrieves lyrics for a [song]. Checks in-memory cache first, then song's embedded
  /// lyrics, then attempts external lookup via LRCLIB if needed.
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

    // 2. Fetch from online lyrics provider
    final fetched = await fetchLyricsByQuery(
      title: song.title,
      artist: song.artist,
      durationSeconds: song.duration.inSeconds > 0 ? song.duration.inSeconds : null,
    );

    if (fetched != null && fetched.trim().isNotEmpty) {
      _cache[cacheKey] = fetched.trim();
      return _cache[cacheKey];
    }

    return null;
  }

  /// Query LRCLIB or external open lyrics API for synchronized or plain lyrics
  Future<String?> fetchLyricsByQuery({
    required String title,
    required String artist,
    int? durationSeconds,
  }) async {
    final cleanTitle = _cleanSongTitle(title);
    final cleanArtist = _cleanArtistName(artist);
    if (cleanTitle.isEmpty) return null;

    final uri = Uri.https('lrclib.net', '/api/get', {
      'track_name': cleanTitle,
      'artist_name': cleanArtist,
      if (durationSeconds != null && durationSeconds > 0)
        'duration': durationSeconds.toString(),
    });

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'JumboMusic/2.0.0 (https://jumbomusic.app)'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final syncedLyrics = data['syncedLyrics'] as String?;
        final plainLyrics = data['plainLyrics'] as String?;

        if (syncedLyrics != null && syncedLyrics.trim().isNotEmpty) {
          return syncedLyrics.trim();
        } else if (plainLyrics != null && plainLyrics.trim().isNotEmpty) {
          return plainLyrics.trim();
        }
      }
    } catch (e) {
      debugPrint('LyricsService fetch note: $e');
    }

    return null;
  }

  /// Manually cache lyrics for a song
  void cacheLyrics(String songId, String lyrics, {String title = '', String artist = ''}) {
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
        .replaceAll(RegExp(r'\(.*?(remix|official|video|audio|lyrics|from).*?\)', caseSensitive: false), '')
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
