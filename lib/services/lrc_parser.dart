/// Represents a single synchronized lyric line with its start timestamp
class LrcLine {
  final Duration timestamp;
  final String text;

  const LrcLine({
    required this.timestamp,
    required this.text,
  });

  @override
  String toString() => '[${timestamp.inMinutes}:${(timestamp.inSeconds % 60).toString().padLeft(2, '0')}.${(timestamp.inMilliseconds % 1000) ~/ 10}] $text';
}

/// High-performance parser and query engine for LRC (synchronized lyrics) format
class LrcParser {
  // Regex pattern matching [mm:ss.xx], [mm:ss.xxx], or [mm:ss]
  static final RegExp _lrcRegex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]');

  /// Parse raw LRC text or plain multi-line string into structured [LrcLine] objects
  static List<LrcLine> parse(String? rawLrc, {Duration totalDuration = Duration.zero}) {
    if (rawLrc == null || rawLrc.trim().isEmpty) {
      return [];
    }

    final lines = rawLrc.split(RegExp(r'\r?\n'));
    final List<LrcLine> parsed = [];
    bool hasAnyTimestamp = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Metadata tags like [ar:Artist], [ti:Title], [al:Album] - skip or ignore
      if (trimmed.startsWith('[ar:') ||
          trimmed.startsWith('[ti:') ||
          trimmed.startsWith('[al:') ||
          trimmed.startsWith('[by:') ||
          trimmed.startsWith('[length:')) {
        continue;
      }

      final matches = _lrcRegex.allMatches(trimmed);
      if (matches.isNotEmpty) {
        hasAnyTimestamp = true;
        // Text is everything after the last timestamp tag
        final lastMatch = matches.last;
        final lyricText = trimmed.substring(lastMatch.end).trim();

        for (final match in matches) {
          final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
          final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
          final millisStr = match.group(3) ?? '0';
          int millis = int.tryParse(millisStr) ?? 0;
          if (millisStr.length == 1) millis *= 100;
          if (millisStr.length == 2) millis *= 10;

          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: millis,
          );

          parsed.add(LrcLine(timestamp: timestamp, text: lyricText));
        }
      }
    }

    // If no timestamps were found, convert plain text lines with evenly spaced timestamps
    if (!hasAnyTimestamp || parsed.isEmpty) {
      final validLines = lines
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('['))
          .toList();

      if (validLines.isEmpty) return [];

      final effectiveDuration = totalDuration.inMilliseconds > 0
          ? totalDuration
          : const Duration(minutes: 3, seconds: 30);

      final intervalMs = (effectiveDuration.inMilliseconds / validLines.length).round();

      for (int i = 0; i < validLines.length; i++) {
        parsed.add(
          LrcLine(
            timestamp: Duration(milliseconds: i * intervalMs),
            text: validLines[i],
          ),
        );
      }
    } else {
      // Sort in ascending order of timestamps
      parsed.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return parsed;
  }

  /// Returns the index of the active lyric line for the given audio position
  static int findActiveIndex(List<LrcLine> lines, Duration position) {
    if (lines.isEmpty) return -1;
    if (position < lines.first.timestamp) return 0;

    int low = 0;
    int high = lines.length - 1;
    int result = 0;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (lines[mid].timestamp <= position) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return result;
  }
}
