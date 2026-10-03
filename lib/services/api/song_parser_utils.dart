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
}
