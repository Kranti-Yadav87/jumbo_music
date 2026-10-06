import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/services/lyrics_service.dart';
import 'package:jumbo_music/widgets/equalizer_bars.dart';
import 'package:jumbo_music/widgets/now_playing/now_playing_lyrics_sheet.dart';

void main() {
  group('NowPlayingLyricsSheet Widget & Active-Line Tests', () {
    late MusicPlayerManager manager;

    setUp(() {
      manager = MusicPlayerManager();
      LyricsService.instance.clearCache();
    });

    const testSongWithSyncedLyrics = Song(
      id: 'test_lrc_song',
      title: 'Tum Hi Ho',
      artist: 'Arijit Singh',
      duration: Duration(seconds: 180),
      audioUrl: 'https://example.com/audio.mp3',
      coverUrl: 'https://example.com/cover.jpg',
      lyrics:
          '[00:00.00]Hum tere bin ab reh nahi sakte\n'
          '[00:05.00]Tere bina kya wajood mera\n'
          '[00:10.00]Tujhse juda agar ho jaayenge',
    );

    const testSongWithoutLyrics = Song(
      id: 'test_empty_song',
      title: 'Instrumental',
      artist: 'Unknown',
      duration: Duration(seconds: 120),
      audioUrl: 'https://example.com/instrumental.mp3',
      coverUrl: 'https://example.com/cover.jpg',
      lyrics: '',
    );

    testWidgets('renders loading and then displays parsed synced lyrics', (
      tester,
    ) async {
      manager.positionNotifier.value = Duration.zero;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NowPlayingLyricsSheet(
              manager: manager,
              song: testSongWithSyncedLyrics,
            ),
          ),
        ),
      );

      // Settle the lyrics future
      await tester.pumpAndSettle();

      expect(find.text('Lyrics • Tum Hi Ho'), findsOneWidget);
      expect(find.text('Hum tere bin ab reh nahi sakte'), findsOneWidget);
      expect(find.text('Tere bina kya wajood mera'), findsOneWidget);
      expect(find.text('Tujhse juda agar ho jaayenge'), findsOneWidget);
    });

    testWidgets(
      'updates active line when manager.positionListenable advances',
      (tester) async {
        manager.positionNotifier.value = Duration.zero;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NowPlayingLyricsSheet(
                manager: manager,
                song: testSongWithSyncedLyrics,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // At position 0s, line 0 is active and should render EqualizerBars
        expect(find.byType(EqualizerBars), findsOneWidget);
        expect(
          find.text('0:00'),
          findsNothing,
        ); // Active line shows EqualizerBars instead of timestamp
        expect(find.text('0:05'), findsOneWidget);
        expect(find.text('0:10'), findsOneWidget);

        // Advance position to 6s (line 1 should now be active)
        manager.positionNotifier.value = const Duration(seconds: 6);
        await tester.pump();

        expect(find.byType(EqualizerBars), findsOneWidget);
        expect(
          find.text('0:00'),
          findsOneWidget,
        ); // Past line now shows timestamp
        expect(
          find.text('0:05'),
          findsNothing,
        ); // Active line shows EqualizerBars
        expect(find.text('0:10'), findsOneWidget);

        // Advance position to 12s (line 2 is now active)
        manager.positionNotifier.value = const Duration(seconds: 12);
        await tester.pump();

        expect(find.text('0:00'), findsOneWidget);
        expect(find.text('0:05'), findsOneWidget);
        expect(
          find.text('0:10'),
          findsNothing,
        ); // Active line shows EqualizerBars
      },
    );

    testWidgets('tapping a lyric line triggers manager.seek', (tester) async {
      manager.positionNotifier.value = Duration.zero;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NowPlayingLyricsSheet(
              manager: manager,
              song: testSongWithSyncedLyrics,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the second lyric line [00:05.00]
      await tester.tap(find.text('Tere bina kya wajood mera'));
      await tester.pump();

      expect(manager.position.inSeconds, equals(5));
    });

    testWidgets('renders empty state when song has no lyrics', (tester) async {
      LyricsService.instance.remoteFetcher =
          ({
            required String title,
            required String artist,
            int? durationSeconds,
          }) async => null;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NowPlayingLyricsSheet(
              manager: manager,
              song: testSongWithoutLyrics,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No lyrics available for this track'), findsOneWidget);

      LyricsService.instance.remoteFetcher = null;
    });
  });
}
