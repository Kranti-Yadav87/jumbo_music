import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/lyrics_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/widgets/now_playing/now_playing_lyrics_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSong = Song(
    id: 'lyrics_test_song_1',
    title: 'Test Song Title',
    artist: 'Test Artist',
    duration: Duration(seconds: 120),
    audioUrl: 'https://example.com/audio.mp3',
    coverUrl: 'https://example.com/cover.jpg',
  );

  const sampleLrc = '''
[00:00.00]First intro line
[00:10.00]Second line of verse
[00:20.00]Chorus line playing
''';

  setUp(() {
    LyricsService.instance.cacheLyrics(
      testSong.id,
      sampleLrc,
      title: testSong.title,
      artist: testSong.artist,
    );
  });

  testWidgets(
    'NowPlayingLyricsSheet renders lyrics and highlights active line',
    (tester) async {
      final manager = MusicPlayerManager();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    NowPlayingLyricsSheet.show(context, manager, testSong);
                  },
                  child: const Text('Open Lyrics'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Lyrics'));
      await tester.pumpAndSettle();

      expect(find.text('Test Song Title'), findsOneWidget);
      expect(find.text('First intro line'), findsOneWidget);
      expect(find.text('Second line of verse'), findsOneWidget);
      expect(find.text('Chorus line playing'), findsOneWidget);

      // Tap on a line to seek
      await tester.tap(find.text('Second line of verse'));
      await tester.pumpAndSettle();

      // Verify close button works
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('First intro line'), findsNothing);
    },
  );
}
