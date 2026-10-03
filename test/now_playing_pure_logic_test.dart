import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/widgets/now_playing/now_playing_queue_sheet.dart';

void main() {
  group('NowPlaying Pure Logic Tests', () {
    test('formatQueueDuration formats hours, minutes, and seconds properly', () {
      final songs = [
        const Song(
          id: '1',
          title: 'Song 1',
          artist: 'Artist 1',
          duration: Duration(seconds: 120), // 2m
          audioUrl: '',
          coverUrl: '',
        ),
        const Song(
          id: '2',
          title: 'Song 2',
          artist: 'Artist 2',
          duration: Duration(seconds: 180), // 3m
          audioUrl: '',
          coverUrl: '',
        ),
      ];

      expect(NowPlayingQueueSheet.formatQueueDuration(songs), equals('5m 0s'));

      final longQueue = [
        const Song(
          id: '1',
          title: 'Long Song',
          artist: 'Artist',
          duration: Duration(seconds: 3665), // 1h 1m 5s
          audioUrl: '',
          coverUrl: '',
        ),
      ];

      expect(NowPlayingQueueSheet.formatQueueDuration(longQueue), equals('1h 1m 5s'));
    });
  });
}
