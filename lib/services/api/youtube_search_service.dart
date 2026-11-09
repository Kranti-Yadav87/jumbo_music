import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../config/app_config.dart';
import '../../models/song.dart';
import '../crash_reporting_service.dart';
import 'music_tag_classifier.dart';

/// Service for YouTube Music catalog search using YouTube Music's InnerTube API
/// and youtube_explode_dart.
/// Uses the API Key from ytmusicapi: `AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30`.
class YouTubeSearchService {
  YouTubeSearchService._();

  static const String _ytmBaseUrl =
      'https://music.youtube.com/youtubei/v1/search?alt=json&key=';

  /// Normalizes user queries by removing conversational connectors like "by",
  /// "song", "audio", "video", "official", "mp3" that are not part of song metadata.
  static String normalizeQuery(String query) {
    String q = query.trim();
    // Replace standalone "by" surrounded by whitespace with a single space
    q = q.replaceAll(RegExp(r'\s+by\s+', caseSensitive: false), ' ');
    // Remove standalone "by" at start or end
    q = q.replaceAll(
      RegExp(r'(^\s*by\s+|\s+by\s*$)', caseSensitive: false),
      ' ',
    );
    // Remove common media suffixes
    q = q.replaceAll(
      RegExp(
        r'\b(songs?|gaana|geet|audio|video|mp3|official)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    q = q.replaceAll(RegExp(r'\s+'), ' ').trim();
    return q.isNotEmpty ? q : query.trim();
  }

  /// Performs a live search on YouTube Music for songs matching [query].
  static Future<List<Song>> search(String query, {int limit = 20}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // 1. Initial primary query search
    List<Song> results = await _executeSearch(cleanQuery, limit: limit);

    // 2. Dual-pass normalization: If primary query contains conversational connectors
    // (e.g. "heer by afusic", "kesariya by arijit") and returned 0 or few results,
    // retry with the normalized query ("heer afusic").
    final normalized = normalizeQuery(cleanQuery);
    if (normalized != cleanQuery && (results.isEmpty || results.length < 3)) {
      final fallbackResults = await _executeSearch(normalized, limit: limit);
      if (fallbackResults.isNotEmpty) {
        final existingIds = results.map((s) => s.id).toSet();
        for (final s in fallbackResults) {
          if (existingIds.add(s.id)) {
            results.add(s);
          }
          if (results.length >= limit) break;
        }
      }
    }

    return results;
  }

  static Future<List<Song>> _executeSearch(
    String query, {
    int limit = 20,
  }) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        if (kIsWeb) {
          // In browser (Flutter Web / localhost / PWA), use proxy endpoint to avoid browser CORS block
          final webUrl = Uri.base.resolve(
            '/api/youtube-search?q=${Uri.encodeComponent(query)}',
          );
          final response = await http
              .get(webUrl)
              .timeout(const Duration(seconds: 14));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic>) {
              return parseSearchResults(data, limit: limit);
            }
          }
        } else {
          // On native platforms (Android APK, iOS, macOS, Windows, Linux)
          final apiKey = AppConfig.youtubeApiKey;
          final uri = Uri.parse('$_ytmBaseUrl$apiKey');

          final headers = <String, String>{
            'Content-Type': 'application/json',
            'Origin': 'https://music.youtube.com',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0',
          };

          final body = jsonEncode({
            'context': {
              'client': {
                'clientName': 'WEB_REMIX',
                'clientVersion': '1.20261024.01.00',
              },
              'user': {},
            },
            'query': query,
            'params': 'EgWKAQIIAWoMEA4QChADEAQQCRAF', // Songs filter param
          });

          final response = await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 14));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic>) {
              return parseSearchResults(data, limit: limit);
            }
          }
        }
      } catch (error) {
        if (attempt == 1) {
          CrashReportingService.swallow(
            error,
            'youtube_search_service.dart:_executeSearch',
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return [];
  }

  /// Fetches official YouTube Music Radio recommendations for a [videoId].
  /// Uses YouTube Music's InnerTube /v1/next endpoint with RDAMVM playlist.
  static Future<List<Song>> fetchRadioRecommendations(
    String videoId, {
    int limit = 50,
  }) async {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty) return [];

    try {
      final apiKey = AppConfig.youtubeApiKey;
      final Uri uri;
      if (kIsWeb) {
        uri = Uri.base.resolve('/api/yt/v1/next?alt=json&key=$apiKey');
      } else {
        uri = Uri.parse(
          'https://music.youtube.com/youtubei/v1/next?alt=json&key=$apiKey',
        );
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Origin': 'https://music.youtube.com',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0',
      };

      final body = jsonEncode({
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.20261024.01.00',
          },
          'user': {},
        },
        'playlistId': 'RDAMVM$cleanId',
        'videoId': cleanId,
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return parseRadioResults(data, limit: limit);
        }
      }
    } catch (error) {
      CrashReportingService.swallow(
        error,
        'youtube_search_service.dart:fetchRadioRecommendations',
      );
    }
    return [];
  }

  /// Resolves direct audio stream for a YouTube video.
  /// On Native: uses youtube_explode_dart to extract high-bitrate .googlevideo.com audio stream.
  /// On Web: returns the proxy stream endpoint /api/youtube-stream?id=$videoId.
  static Future<String?> resolveAudioStream(String videoId) async {
    if (videoId.isEmpty) return null;
    if (kIsWeb) {
      return '/api/youtube-stream?id=$videoId';
    }
    try {
      final yt = YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient.getManifest(videoId);
        final audio = manifest.audioOnly.withHighestBitrate();
        return audio.url.toString();
      } finally {
        yt.close();
      }
    } catch (e) {
      debugPrint('Error resolving YouTube audio stream: $e');
    }
    return null;
  }

  /// Parses YouTube Music InnerTube search response into structured [Song] objects.
  static List<Song> parseSearchResults(
    Map<String, dynamic> data, {
    int limit = 20,
  }) {
    final List<Song> songs = [];
    try {
      final contents = data['contents'];
      if (contents is! Map) return songs;

      final tabbed = contents['tabbedSearchResultsRenderer'];
      if (tabbed is! Map) return songs;

      final tabs = tabbed['tabs'];
      if (tabs is! List || tabs.isEmpty) return songs;

      final tabContent = tabs[0]['tabRenderer']?['content'];
      if (tabContent is! Map) return songs;

      final sectionList = tabContent['sectionListRenderer'];
      if (sectionList is! Map) return songs;

      final sections = sectionList['contents'];
      if (sections is! List) return songs;

      for (final sec in sections) {
        if (sec is! Map) continue;

        // 1. Check for Top Result Hero Card (musicCardShelfRenderer)
        final card = sec['musicCardShelfRenderer'];
        if (card is Map) {
          String cardVideoId = '';
          final onTap = card['onTap'];
          if (onTap is Map) {
            cardVideoId = onTap['watchEndpoint']?['videoId']?.toString() ?? '';
          }
          if (cardVideoId.isEmpty) {
            final buttons = card['buttons'];
            if (buttons is List && buttons.isNotEmpty && buttons[0] is Map) {
              cardVideoId =
                  buttons[0]['musicPlayButtonRenderer']?['playNavigationEndpoint']?['watchEndpoint']?['videoId']
                      ?.toString() ??
                  '';
            }
          }
          if (cardVideoId.isEmpty) {
            final titleObj = card['title'];
            if (titleObj is Map &&
                titleObj['runs'] is List &&
                (titleObj['runs'] as List).isNotEmpty) {
              final r0 = (titleObj['runs'] as List)[0];
              if (r0 is Map) {
                cardVideoId =
                    r0['navigationEndpoint']?['watchEndpoint']?['videoId']
                        ?.toString() ??
                    '';
              }
            }
          }

          if (cardVideoId.isNotEmpty) {
            String cardTitle = '';
            final titleRuns = card['title']?['runs'];
            if (titleRuns is List &&
                titleRuns.isNotEmpty &&
                titleRuns[0] is Map) {
              cardTitle = titleRuns[0]['text']?.toString().trim() ?? '';
            }

            if (cardTitle.isNotEmpty) {
              String cardArtist = 'Various Artists';
              String cardAlbum = 'Single';
              Duration cardDuration = const Duration(seconds: 240);

              final subRuns = card['subtitle']?['runs'];
              if (subRuns is List && subRuns.isNotEmpty) {
                final segments = <String>[];
                String cur = '';
                for (final r in subRuns) {
                  if (r is! Map) continue;
                  final text = r['text']?.toString() ?? '';
                  if (text.trim() == '•') {
                    if (cur.trim().isNotEmpty) {
                      segments.add(cur.trim());
                      cur = '';
                    }
                  } else {
                    cur += text;
                  }
                }
                if (cur.trim().isNotEmpty) segments.add(cur.trim());

                for (final seg in segments) {
                  final d = _parseDuration(seg);
                  if (d != null && d.inSeconds > 0) {
                    cardDuration = d;
                    continue;
                  }
                  if (seg.toLowerCase() == 'song' ||
                      seg.toLowerCase() == 'video')
                    continue;
                  if (cardArtist == 'Various Artists') {
                    cardArtist = seg;
                  } else if (cardAlbum == 'Single') {
                    cardAlbum = seg;
                  }
                }
              }

              final thumbs =
                  card['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
              final coverUrl = _extractCover(thumbs, cardVideoId);
              final song = _buildSong(
                videoId: cardVideoId,
                title: cardTitle,
                artist: cardArtist,
                album: cardAlbum,
                duration: cardDuration,
                coverUrl: coverUrl,
              );
              if (!songs.any((s) => s.id == song.id)) {
                songs.add(song);
              }
            }
          }
        }

        // 2. Check for Standard Songs Shelf (musicShelfRenderer)
        final shelf =
            sec['musicShelfRenderer'] ?? sec['musicCardShelfRenderer'];
        if (shelf is! Map) continue;

        final shelfContents = shelf['contents'];
        if (shelfContents is! List) continue;

        for (final item in shelfContents) {
          if (songs.length >= limit) break;
          if (item is! Map) continue;

          final mrf = item['musicResponsiveListItemRenderer'];
          if (mrf is! Map) continue;

          // 1. Video ID
          String videoId =
              mrf['playlistItemData']?['videoId']?.toString() ?? '';
          if (videoId.isEmpty) {
            videoId =
                mrf['navigationEndpoint']?['watchEndpoint']?['videoId']
                    ?.toString() ??
                '';
          }
          if (videoId.isEmpty) continue;

          // 2. Flex Columns: Col 0 is Title, Col 1 is Artist / Album / Duration
          final flexCols = mrf['flexColumns'];
          if (flexCols is! List || flexCols.isEmpty) continue;

          // Extract Title
          String title = '';
          final col0 = flexCols[0];
          if (col0 is Map) {
            final runs =
                col0['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
            if (runs is List && runs.isNotEmpty && runs[0] is Map) {
              title = runs[0]['text']?.toString().trim() ?? '';
            }
          }
          if (title.isEmpty) continue;

          // Extract Artist, Album, Duration from Col 1
          String artist = 'Various Artists';
          String album = 'Single';
          String releaseYear = '';
          Duration duration = const Duration(seconds: 240);

          if (flexCols.length > 1 && flexCols[1] is Map) {
            final runs =
                flexCols[1]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
            if (runs is List && runs.isNotEmpty) {
              final segments = <String>[];
              String current = '';
              for (final r in runs) {
                if (r is! Map) continue;
                final text = r['text']?.toString() ?? '';
                if (text.isEmpty) continue;
                if (text.trim() == '•') {
                  if (current.trim().isNotEmpty) {
                    segments.add(current.trim());
                    current = '';
                  }
                } else {
                  current += text;
                }
              }
              if (current.trim().isNotEmpty) {
                segments.add(current.trim());
              }

              if (segments.isNotEmpty) {
                artist = segments[0].trim();
              }

              for (int i = 1; i < segments.length; i++) {
                final seg = segments[i].trim();
                final d = _parseDuration(seg);
                if (d != null && d.inSeconds > 0) {
                  duration = d;
                  continue;
                }
                final yearMatch = RegExp(
                  r'\b(19\d{2}|20\d{2})\b',
                ).firstMatch(seg);
                if (yearMatch != null && seg.length <= 6) {
                  releaseYear = yearMatch.group(1)!;
                  continue;
                }
                if (album == 'Single' &&
                    !seg.contains('views') &&
                    !seg.contains('plays')) {
                  album = seg;
                }
              }
            }
          }

          final songId = 'yt_$videoId';
          if (songs.any((s) => s.id == songId)) continue;
          final thumbObj =
              mrf['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
          final coverUrl = _extractCover(thumbObj, videoId);
          songs.add(
            _buildSong(
              videoId: videoId,
              title: title,
              artist: artist,
              album: album,
              duration: duration,
              coverUrl: coverUrl,
              releaseYear: releaseYear,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing YouTube Music search results: $e');
    }
    return songs;
  }

  /// Parses YouTube Music InnerTube radio response into structured [Song] objects.
  static List<Song> parseRadioResults(
    Map<String, dynamic> data, {
    int limit = 50,
  }) {
    final List<Song> songs = [];
    try {
      final contents = data['contents'];
      if (contents is! Map) return songs;

      final singleCol = contents['singleColumnMusicWatchNextResultsRenderer'];
      if (singleCol is! Map) return songs;

      final tabbed = singleCol['tabbedRenderer'];
      if (tabbed is! Map) return songs;

      final watchNext = tabbed['watchNextTabbedResultsRenderer'];
      if (watchNext is! Map) return songs;

      final tabs = watchNext['tabs'];
      if (tabs is! List || tabs.isEmpty) return songs;

      final tab0 = tabs[0];
      if (tab0 is! Map) return songs;

      final tabRenderer = tab0['tabRenderer'];
      if (tabRenderer is! Map) return songs;

      final tabContent = tabRenderer['content'];
      if (tabContent is! Map) return songs;

      final queueRenderer = tabContent['musicQueueRenderer'];
      if (queueRenderer is! Map) return songs;

      final queueContent = queueRenderer['content'];
      if (queueContent is! Map) return songs;

      final panelRenderer = queueContent['playlistPanelRenderer'];
      if (panelRenderer is! Map) return songs;

      final panelContents = panelRenderer['contents'];
      if (panelContents is! List) return songs;

      for (final item in panelContents) {
        if (songs.length >= limit) break;
        if (item is! Map) continue;

        final video = item['playlistPanelVideoRenderer'];
        if (video is! Map) continue;

        final videoId = video['videoId']?.toString() ?? '';
        if (videoId.isEmpty) continue;

        // Title
        String title = '';
        final titleMap = video['title'];
        if (titleMap is Map && titleMap['runs'] is List) {
          title = (titleMap['runs'] as List)
              .map((r) => r is Map ? (r['text']?.toString() ?? '') : '')
              .join('')
              .trim();
        }
        if (title.isEmpty) continue;

        // Artist & Album from byline
        String artist = '';
        final shortByline = video['shortBylineText'];
        if (shortByline is Map && shortByline['runs'] is List) {
          artist = (shortByline['runs'] as List)
              .map((r) => r is Map ? (r['text']?.toString() ?? '') : '')
              .join('')
              .trim();
        }

        String album = 'YouTube Music';
        String releaseYear = '';
        final longByline = video['longBylineText'];
        if (longByline is Map && longByline['runs'] is List) {
          final bylineParts = (longByline['runs'] as List)
              .map((r) => r is Map ? (r['text']?.toString() ?? '') : '')
              .join('')
              .split('•')
              .map((p) => p.trim())
              .toList();
          if (artist.isEmpty && bylineParts.isNotEmpty) {
            artist = bylineParts[0];
          }
          if (bylineParts.length >= 2) {
            album = bylineParts[1];
          }
          for (final part in bylineParts) {
            final match = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(part);
            if (match != null) {
              releaseYear = match.group(1)!;
              break;
            }
          }
        }
        if (artist.isEmpty) artist = 'Unknown Artist';

        // Duration
        Duration duration = Duration.zero;
        final lengthText = video['lengthText'];
        if (lengthText is Map && lengthText['runs'] is List) {
          final durStr = (lengthText['runs'] as List)
              .map((r) => r is Map ? (r['text']?.toString() ?? '') : '')
              .join('')
              .trim();
          duration = _parseDuration(durStr) ?? Duration.zero;
        }

        // Thumbnail
        String coverUrl = '';
        final thumbnailMap = video['thumbnail'];
        if (thumbnailMap is Map && thumbnailMap['thumbnails'] is List) {
          final thumbs = thumbnailMap['thumbnails'] as List;
          if (thumbs.isNotEmpty) {
            final lastThumb = thumbs.last;
            if (lastThumb is Map && lastThumb['url'] != null) {
              coverUrl = lastThumb['url'].toString();
            }
          }
        }

        final songId = 'yt_$videoId';
        final language = MusicTagClassifier.detectTextLanguage(
          title: title,
          artist: artist,
          album: album,
          genre: 'YouTube Music',
          audioUrl: '',
          id: songId,
        );

        final audioUrl = kIsWeb
            ? '/api/youtube-stream?id=$videoId'
            : 'https://music.youtube.com/watch?v=$videoId';

        songs.add(
          Song(
            id: songId,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            audioUrl: audioUrl,
            coverUrl: coverUrl,
            genre: 'YouTube Music',
            language: language,
            releaseYear: releaseYear,
            quality: 'YouTube HD',
            lyrics: '',
            isLiveStream: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error parsing YouTube Music radio results: $e');
    }
    return songs;
  }

  static String _extractCover(dynamic thumbObj, String videoId) {
    if (thumbObj is List && thumbObj.isNotEmpty) {
      final last = thumbObj.last;
      if (last is Map && last['url'] != null) {
        final url = last['url'].toString().replaceAll(
          RegExp(r'=w\d+-h\d+.*'),
          '=w540-h540-l90-rj',
        );
        return url.startsWith('http://')
            ? url.replaceFirst('http://', 'https://')
            : url;
      }
    }
    return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  }

  static Song _buildSong({
    required String videoId,
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    required String coverUrl,
    String releaseYear = '',
  }) {
    final songId = 'yt_$videoId';
    final language = MusicTagClassifier.detectTextLanguage(
      title: title,
      artist: artist,
      album: album,
      genre: 'YouTube Music',
      audioUrl: '',
      id: songId,
    );

    final audioUrl = kIsWeb
        ? '/api/youtube-stream?id=$videoId'
        : 'https://music.youtube.com/watch?v=$videoId';

    return Song(
      id: songId,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      audioUrl: audioUrl,
      coverUrl: coverUrl,
      genre: 'YouTube Music',
      language: language,
      releaseYear: releaseYear,
      quality: 'YouTube HD',
      lyrics: '',
      isLiveStream: false,
    );
  }

  static Duration? _parseDuration(String text) {
    final parts = text.trim().split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) {
        return Duration(minutes: m, seconds: s);
      }
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h != null && m != null && s != null) {
        return Duration(hours: h, minutes: m, seconds: s);
      }
    }
    return null;
  }
}
