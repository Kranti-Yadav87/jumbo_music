import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/release_filter.dart';

Song _s(String id, String year) => Song(
  id: id,
  title: 't$id',
  artist: 'a',
  duration: const Duration(seconds: 200),
  audioUrl: 'https://x/$id.mp3',
  coverUrl: '',
  releaseYear: year,
);

void main() {
  group('ReleaseFilter.pickNewReleases', () {
    test('keeps only songs from the current year when enough exist', () {
      final songs = [
        for (var i = 0; i < 8; i++) _s('n$i', '2026'),
        _s('old1', '2019'),
        _s('old2', '2024'),
      ];
      final r = ReleaseFilter.pickNewReleases(songs, year: 2026);
      expect(r.length, 8);
      expect(r.every((s) => s.releaseYear == '2026'), isTrue);
    });

    test('falls back to previous year when too few are new', () {
      final songs = [_s('a', '2026'), _s('b', '2025'), _s('c', '2025'), _s('d', '2010')];
      final r = ReleaseFilter.pickNewReleases(songs, year: 2026);
      expect(r.map((s) => s.id), containsAll(['a', 'b', 'c']));
      expect(r.map((s) => s.id), isNot(contains('d')));
      expect(r.first.id, 'a'); // newest first
    });

    test('drops duplicates and unknown / future years', () {
      final songs = [_s('a', '2026'), _s('a', '2026'), _s('u', ''), _s('f', '2031')];
      final r = ReleaseFilter.pickNewReleases(songs, year: 2026, minCount: 1);
      expect(r.map((s) => s.id).toList(), ['a']);
    });
  });
}
