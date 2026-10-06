import 'dart:math';

/// Helper for generating and validating Live Jam room codes.
class JamRoomHelper {
  JamRoomHelper._();

  // Character set excluding visually ambiguous characters:
  // Excluded: '0' (zero), 'O' (oh), '1' (one), 'I' (eye), 'L' (el)
  static const String safeCharset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Generates a unique Live Jam room code formatted as JUMBO-XXXXXX
  /// (e.g. `JUMBO-A8K9X2`).
  static String generateRoomCode({Random? random}) {
    final rng = random ?? Random();
    final buffer = StringBuffer('JUMBO-');
    for (int i = 0; i < 6; i++) {
      buffer.write(safeCharset[rng.nextInt(safeCharset.length)]);
    }
    return buffer.toString();
  }

  /// Normalizes room code to standard format `JUMBO-XXXXXX`
  static String normalizeRoomCode(String code) {
    String trimmed = code.trim().toUpperCase();
    if (trimmed.startsWith('JUMBO-')) {
      return trimmed;
    }
    if (trimmed.startsWith('JUMBO')) {
      trimmed = trimmed.substring('JUMBO'.length).trim();
      if (trimmed.startsWith('-')) trimmed = trimmed.substring(1).trim();
    }
    return 'JUMBO-$trimmed';
  }

  /// Checks whether [code] is a valid format for a Live Jam room code.
  static bool isValidRoomCode(String? code) {
    if (code == null) return false;
    final normalized = normalizeRoomCode(code);
    if (!normalized.startsWith('JUMBO-')) return false;
    final suffix = normalized.substring('JUMBO-'.length);
    if (suffix.length != 6) return false;
    for (int i = 0; i < suffix.length; i++) {
      if (!safeCharset.contains(suffix[i])) {
        return false;
      }
    }
    return true;
  }
}
