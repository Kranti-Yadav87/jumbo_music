import '../../models/song.dart';

/// Pure parsing utility functions for music API responses.
class SongParserUtils {
  SongParserUtils._();

  static String unescape(String? input) {
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

  static String extractImage(dynamic imageObj) {
    if (imageObj == null) return '';
    String result = '';
    if (imageObj is String) {
      result = imageObj;
    } else if (imageObj is List && imageObj.isNotEmpty) {
      for (final item in imageObj.reversed) {
        if (item is Map) {
          final url =
              (item['url'] as String?) ?? (item['link'] as String?) ?? '';
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
        result =
            (imageObj.first['url'] as String?) ??
            (imageObj.first['link'] as String?) ??
            '';
      }
    } else if (imageObj is Map) {
      result =
          (imageObj['url'] as String?) ?? (imageObj['link'] as String?) ?? '';
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

  static String extractAudioUrl(dynamic downloadUrlObj) {
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

  static String extractArtists(dynamic item) {
    if (item == null) return 'Unknown Artist';
    if (item['artists'] != null && item['artists']['primary'] != null) {
      final primaries = item['artists']['primary'];
      if (primaries is List) {
        final names = primaries
            .map((a) => a['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        if (names.isNotEmpty) return unescape(names.join(', '));
      }
    }
    if (item['primaryArtists'] != null && item['primaryArtists'] is String) {
      return unescape(item['primaryArtists']);
    }
    if (item['subtitle'] != null && item['subtitle'] is String) {
      final sub = item['subtitle'] as String;
      return unescape(sub.split(' - ').first);
    }
    return 'Unknown Artist';
  }

  static Song? parseSong(Map<String, dynamic> item) {
    try {
      final audioUrl = extractAudioUrl(item['downloadUrl']);
      final name = unescape(item['name'] ?? item['song'] ?? item['title']);
      if (audioUrl.isEmpty || name.isEmpty) return null;

      final lowerName = name.toLowerCase();
      // Filter out short ringtones, caller tunes, trailers, dialogue promos
      if (lowerName.contains('ringtone') ||
          lowerName.contains('caller tune') ||
          lowerName.contains('dialogue promo') ||
          lowerName.contains('official trailer') ||
          lowerName.contains('teaser') ||
          lowerName.contains('30 sec') ||
          lowerName.contains('30sec')) {
        return null;
      }

      final artist = extractArtists(item);
      final rawAlbum = item['album'];
      final album = rawAlbum is Map
          ? unescape(rawAlbum['name'] as String?)
          : unescape(rawAlbum as String? ?? 'Single');

      final coverUrl = extractImage(item['image']);
      final id =
          (item['id'] as String?) ??
          'song_${DateTime.now().millisecondsSinceEpoch}';

      final durationSec =
          int.tryParse(item['duration']?.toString() ?? '0') ?? 240;
      // Filter out tracks shorter than 60s (unless duration wasn't supplied by API)
      if (durationSec > 0 && durationSec < 60) {
        return null;
      }

      final year = item['year']?.toString().trim() ?? '';

      // Extract language from metadata if present
      String rawLang =
          (item['language'] as String?) ?? (item['lang'] as String?) ?? '';
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
      } else if (rawLang.contains('marathi')) {
        normalizedLang = 'Marathi';
      } else if (rawLang.contains('bengali') || rawLang.contains('bangla')) {
        normalizedLang = 'Bengali';
      } else if (rawLang.contains('gujarati')) {
        normalizedLang = 'Gujarati';
      } else if (rawLang.contains('kannada')) {
        normalizedLang = 'Kannada';
      } else if (rawLang.contains('malayalam')) {
        normalizedLang = 'Malayalam';
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
        lyrics: (item['lyrics'] as String?)?.trim() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Normalizes a song title by lowercasing, stripping parentheses content like
  /// (From "Movie"), (feat. Artist), [Remastered], (Lofi), etc., and punctuation.
  static String normalizeSongTitle(String title) {
    var clean = unescape(title).toLowerCase().trim();
    // Remove content inside parentheses, brackets, braces
    clean = clean.replaceAll(RegExp(r'\s*[\(\[\{][^\)\]\}]*[\)\]\}]'), ' ');
    // Remove common trailing prefixes like "- From ...", "- Remastered", etc.
    clean = clean.replaceAll(
      RegExp(
        r'\s*-\s*(from|remastered|lofi|original|reprise|acoustic|bonus|extended).*$',
      ),
      '',
    );
    // Remove punctuation
    clean = clean.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    // Collapse multiple spaces
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean;
  }

  /// Normalizes primary artist name
  static String normalizeArtist(String artist) {
    var clean = unescape(artist).toLowerCase().trim();
    clean = clean.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.split(' ').first; // Use primary artist first name
  }

  /// Returns a canonical identity string for a song to prevent duplicate suggestions
  static String songDeduplicationKey(Song song) {
    final t = normalizeSongTitle(song.title);
    final a = normalizeArtist(song.artist);
    if (t.isNotEmpty) {
      return '$t|$a';
    }
    return song.id;
  }

  /// Deduplicates a list of songs by ID and by canonical title+artist identity
  static List<Song> deduplicateSongs(Iterable<Song> songs) {
    final Set<String> seenIds = {};
    final Set<String> seenKeys = {};
    final List<Song> result = [];

    for (final song in songs) {
      final key = songDeduplicationKey(song);
      if (seenIds.add(song.id) && seenKeys.add(key)) {
        result.add(song);
      }
    }
    return result;
  }
}
