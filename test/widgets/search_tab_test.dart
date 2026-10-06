import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/screens/search_tab.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/music_api_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockSong1 = Song(
    id: 'mock_song_1',
    title: 'Channa Mereya',
    artist: 'Arijit Singh',
    album: 'Ae Dil Hai Mushkil',
    duration: Duration(seconds: 289),
    coverUrl: '',
    audioUrl: 'https://example.com/channa.mp3',
  );

  const mockSong2 = Song(
    id: 'mock_song_2',
    title: 'Raabta',
    artist: 'Arijit Singh',
    album: 'Agent Vinod',
    duration: Duration(seconds: 243),
    coverUrl: '',
    audioUrl: 'https://example.com/raabta.mp3',
  );

  Widget buildTestableSearchTab() {
    return const MaterialApp(home: Scaffold(body: SearchTab()));
  }

  group('SearchTab Widget Tests', () {
    late DatabaseService db;
    late MusicPlayerManager playerManager;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();

      playerManager = MusicPlayerManager();
      playerManager.resetStateForTesting();

      MusicApiService.mockSearchLiveSongs = (query, {int limit = 30}) async {
        final q = query.toLowerCase();
        if (q.contains('arijit') || q.contains('channa')) {
          return [mockSong1, mockSong2];
        }
        return [];
      };
    });

    tearDown(() async {
      MusicApiService.mockSearchLiveSongs = null;
      await db.clearAllUserData();
      playerManager.resetStateForTesting();
    });

    testWidgets(
      'Initial / Empty State: Renders search input and Trending & Discover chips',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableSearchTab());
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search songs, artists, albums...'), findsOneWidget);
        expect(find.text('Trending & Discover'), findsOneWidget);
        expect(find.text('Trending Top 50'), findsOneWidget);
        expect(find.text('Arijit Singh'), findsOneWidget);
        expect(find.text('Bollywood Hits'), findsOneWidget);
      },
    );

    testWidgets(
      'Recent Searches State: Displays saved recent searches with clear all option',
      (WidgetTester tester) async {
        db.addSearchQuery('Mohit Chauhan');
        db.addSearchQuery('Atif Aslam');

        await tester.pumpWidget(buildTestableSearchTab());
        await tester.pumpAndSettle();

        expect(find.text('Recent Searches'), findsOneWidget);
        expect(find.text('Mohit Chauhan'), findsOneWidget);
        expect(find.text('Atif Aslam'), findsOneWidget);
        expect(find.text('Clear all'), findsOneWidget);

        // Tap 'Clear all'
        await tester.tap(find.text('Clear all'));
        await tester.pumpAndSettle();

        expect(find.text('Recent Searches'), findsNothing);
        expect(find.text('Mohit Chauhan'), findsNothing);
        expect(find.text('Trending & Discover'), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: Typing a search query displays matching songs from fake API',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableSearchTab());
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'Arijit');
        // Advance time for debounce timer (300ms)
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(find.text('Top Results (2)'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Channa Mereya'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Raabta'), findsOneWidget);
        expect(find.byType(ListTile), findsNWidgets(2));
      },
    );

    testWidgets(
      'Empty / No Results State: Displays "No results found for ..." when query yields no results',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableSearchTab());
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'UnknownNonExistentTrack999');
        // Advance debounce timer
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(
          find.text('No results found for "UnknownNonExistentTrack999"'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Interactions: Tapping a Trending discovery chip triggers search',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableSearchTab());
        await tester.pumpAndSettle();

        final chip = find.text('Arijit Singh');
        expect(chip, findsOneWidget);

        await tester.tap(chip);
        // Advance debounce timer
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(find.text('Top Results (2)'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Channa Mereya'), findsOneWidget);
      },
    );

    testWidgets(
      'Interactions: Tapping clear button clears text and restores discovery state',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableSearchTab());
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'Arijit');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Channa Mereya'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        // Tap clear button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Channa Mereya'), findsNothing);
        expect(find.text('Trending & Discover'), findsOneWidget);
      },
    );
  });
}
