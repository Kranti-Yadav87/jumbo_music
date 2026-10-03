import '../models/song.dart';

/// Picks genuinely new releases out of a mixed list of songs.
class ReleaseFilter {
  ReleaseFilter._();

  static int? _year(Song s) => int.tryParse(s.releaseYear.trim());

  /// Keeps unique songs released in [year]. If that gives fewer than
  /// [minCount] songs, songs from the previous year are allowed too.
  /// Songs with an unknown release year are never treated as "new".
  static List<Song> pickNewReleases(
    List<Song> songs, {
    required int year,
    int maxItems = 30,
    int minCount = 6,
  }) {
    final seen = <String>{};
    final unique = <Song>[];
    for (final s in songs) {
      if (seen.add(s.id)) unique.add(s);
    }

    List<Song> since(int minYear) => unique.where((s) {
      final y = _year(s);
      return y != null && y >= minYear && y <= year;
    }).toList();

    var picked = since(year);
    if (picked.length < minCount) picked = since(year - 1);

    picked.sort((a, b) => (_year(b) ?? 0).compareTo(_year(a) ?? 0));
    return picked.take(maxItems).toList();
  }
}
