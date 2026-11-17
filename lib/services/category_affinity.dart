import '../models/song.dart';
import 'database_service.dart';

/// Learns which discovery categories a user plays most, so the Home pills
/// can put them first. Data is stored per user in the scoped settings store.
class CategoryAffinity {
  CategoryAffinity._();

  static const String _settingKey = 'category_play_counts';

  static Map<String, int> explicitCounts() {
    final raw = DatabaseService.instance.getSetting(_settingKey);
    if (raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0),
    );
  }

  /// Records that the user played a song while [category] was selected.
  static Future<void> recordPlay(String category) async {
    if (category.isEmpty || category == 'All') return;
    final counts = explicitCounts();
    counts[category] = (counts[category] ?? 0) + 1;
    await DatabaseService.instance.updateSetting(_settingKey, counts);
  }

  /// Best-effort category for a played song, based on its metadata.
  static String inferCategory(Song song) {
    final t = '${song.title} ${song.album} ${song.genre}'.toLowerCase();
    bool has(String pattern) => RegExp(pattern).hasMatch(t);
    if (has(r'podcast|episode')) return 'Podcasts';
    if (has(r'lo-?fi|chill|sukoon|slowed|reverb')) return 'Chill';
    if (has(r'workout|gym|motivation')) return 'Workout';
    if (has(r'party|dance|remix|club|dj ')) return 'Party';
    if (has(r'focus|study|instrumental|piano|meditation')) return 'Focus';
    if (has(r'romantic|romance|love|ishq|pyaar|pyar|dil')) return 'Romance';
    if (has(r'\blive\b|unplugged|concert')) return 'Live';
    if (has(r'bollywood|hindi|from ".*"|film')) return 'Bollywood';
    return 'Music';
  }

  /// Orders [categories] with "All" pinned first, then by how much the user
  /// plays each one (explicit plays weigh 3x, listening history 1x).
  /// Ties keep the original order.
  static List<String> order(
    List<String> categories,
    Map<String, int> explicit,
    List<Song> history,
  ) {
    final scores = <String, int>{};
    explicit.forEach((k, v) => scores[k] = (scores[k] ?? 0) + v * 3);
    for (final song in history.take(100)) {
      final c = inferCategory(song);
      scores[c] = (scores[c] ?? 0) + 1;
    }
    final rest = categories.where((c) => c != 'All').toList();
    final index = {for (var i = 0; i < rest.length; i++) rest[i]: i};
    rest.sort((a, b) {
      final diff = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
      return diff != 0 ? diff : index[a]!.compareTo(index[b]!);
    });
    return [if (categories.contains('All')) 'All', ...rest];
  }

  static List<String> orderedForCurrentUser(List<String> categories) {
    return order(
      categories,
      explicitCounts(),
      DatabaseService.instance.historySongs,
    );
  }
}
