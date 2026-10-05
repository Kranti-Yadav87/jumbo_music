import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/widgets/mini_player.dart';
import 'package:jumbo_music/widgets/now_playing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSong1 = Song(
    id: 'test_mini_1',
    title: 'Tum Hi Ho',
    artist: 'Arijit Singh',
    album: 'Aashiqui 2',
    duration: Duration(seconds: 262),
    coverUrl: '',
    audioUrl: 'https://example.com/tumhiho.mp3',
  );

  const testSong2 = Song(
    id: 'test_mini_2',
    title: 'Kesariya',
    artist: 'Arijit Singh',
    album: 'Brahmastra',
    duration: Duration(seconds: 268),
    coverUrl: '',
    audioUrl: 'https://example.com/kesariya.mp3',
  );

  Widget buildTestableMiniPlayer() {
    return const MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
      ),
    );
  }

  group('MiniPlayer Widget Tests', () {
    late MusicPlayerManager manager;

    setUp(() {
      manager = MusicPlayerManager();
      manager.resetStateForTesting();
    });

    tearDown(() {
      manager.resetStateForTesting();
    });

    testWidgets(
      'Empty State: Renders SizedBox.shrink when currentSong is null',
      (WidgetTester tester) async {
        manager.setMockState(currentSong: null);

        await tester.pumpWidget(buildTestableMiniPlayer());
        await tester.pumpAndSettle();

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Tum Hi Ho'), findsNothing);
        expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
        expect(find.byIcon(Icons.pause_rounded), findsNothing);
      },
    );

    testWidgets(
      'Happy Path: Displays song title, artist, unfavorite icon and play button when song is paused',
      (WidgetTester tester) async {
        manager.setMockState(
          currentSong: testSong1,
          isPlaying: false,
          isBuffering: false,
          favoriteIds: {},
        );

        await tester.pumpWidget(buildTestableMiniPlayer());
        await tester.pumpAndSettle();

        expect(find.text('Tum Hi Ho'), findsOneWidget);
        expect(find.text('Arijit Singh'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(find.byKey(const ValueKey('mini_play')), findsOneWidget);
        expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: Displays filled favorite icon and pause button when song is playing and favorited',
      (WidgetTester tester) async {
        manager.setMockState(
          currentSong: testSong1,
          isPlaying: true,
          isBuffering: false,
          favoriteIds: {testSong1.id},
        );

        await tester.pumpWidget(buildTestableMiniPlayer());
        await tester.pumpAndSettle();

        expect(find.text('Tum Hi Ho'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
        expect(find.byKey(const ValueKey('mini_pause')), findsOneWidget);
      },
    );

    testWidgets(
      'Interactions: Tapping favorite button toggles favorite state',
      (WidgetTester tester) async {
        manager.setMockState(
          currentSong: testSong1,
          isPlaying: false,
          favoriteIds: {},
        );

        await tester.pumpWidget(buildTestableMiniPlayer());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.favorite_border_rounded));
        await tester.pumpAndSettle();

        expect(manager.isFavorite(testSong1.id), isTrue);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.favorite_rounded));
        await tester.pumpAndSettle();

        expect(manager.isFavorite(testSong1.id), isFalse);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Buffering State: Displays circular progress indicator when isBuffering is true and not playing',
      (WidgetTester tester) async {
        manager.setMockState(
          currentSong: testSong1,
          isPlaying: false,
          isBuffering: true,
        );

        await tester.pumpWidget(buildTestableMiniPlayer());
        await tester.pump();

        expect(find.byKey(const ValueKey('mini_buffering')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'Navigation: Tapping title area navigates to NowPlayingScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        manager.setMockState(
          currentSong: testSong1,
          queue: [testSong1, testSong2],
          isPlaying: true,
        );

        await tester.pumpWidget(buildTestableMiniPlayer());
        await tester.pumpAndSettle();

        expect(find.byType(NowPlayingScreen), findsNothing);

        // Tap the title text
        await tester.tap(find.text('Tum Hi Ho'));
        await tester.pumpAndSettle();

        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );
  });
}
