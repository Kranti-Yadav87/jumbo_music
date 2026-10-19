import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/data/music_repository.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/music_api_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/widgets/home/search_inspired_section.dart';
import 'package:jumbo_music/widgets/home/featured_playlists_section.dart';
import 'package:jumbo_music/widgets/home/bts_section.dart';
import 'package:jumbo_music/widgets/home/continue_playing_section.dart';

import 'package:jumbo_music/services/storage/storage_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockSong = Song(
    id: 'test_mock_1',
    title: 'Tum Hi Ho',
    artist: 'Arijit Singh',
    album: 'Aashiqui 2',
    duration: Duration(seconds: 262),
    coverUrl: '',
    audioUrl: 'https://example.com/tumhiho.mp3',
  );

  group('Home Dynamic Sections Tests', () {
    late DatabaseService db;
    late MusicPlayerManager playerManager;

    setUp(() async {
      StorageEngine.inMemoryOnly = true;
      StorageEngine.clearMemoryStorage();

      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();

      playerManager = MusicPlayerManager();
      playerManager.resetStateForTesting();

      MusicApiService.mockSearchLiveSongs = (query, {int limit = 30}) async {
        return [mockSong];
      };
    });

    tearDown(() async {
      MusicApiService.mockSearchLiveSongs = null;
      await db.clearAllUserData();
      playerManager.resetStateForTesting();
      StorageEngine.clearMemoryStorage();
    });

    testWidgets('FeaturedPlaylistsSection renders playlist cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: FeaturedPlaylistsSection()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Featured Playlists For You'), findsOneWidget);
      expect(
        find.text(MusicRepository.featuredPlaylistsForYou.first.title),
        findsOneWidget,
      );
    });

    testWidgets('BtsSection renders header and essentials', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: BtsSection())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('BTS Hits 💜'), findsOneWidget);
    });

    testWidgets(
      'SearchInspiredSection renders query chips from search history',
      (tester) async {
        await db.addSearchQuery('Arijit Singh');
        await db.addSearchQuery('Taylor Swift');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: SearchInspiredSection()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Inspired by your search'), findsOneWidget);
        expect(find.text('Arijit Singh'), findsWidgets);
        expect(find.text('Taylor Swift'), findsOneWidget);
      },
    );

    testWidgets(
      'SearchInspiredSection falls back to listening history when search history is empty',
      (tester) async {
        await db.clearSearchHistory();
        await db.addHistory(mockSong);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: SearchInspiredSection()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Inspired by your listening'), findsOneWidget);
        expect(find.text('Arijit Singh'), findsWidgets);
      },
    );

    testWidgets(
      'SearchInspiredSection shows Trending for you when both search and history are empty',
      (tester) async {
        await db.clearSearchHistory();
        await db.clearHistory();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: SearchInspiredSection()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Trending for you'), findsOneWidget);
        expect(find.text('Trending Hits'), findsWidgets);
      },
    );

    test(
      'DatabaseService saves and restores last played song and queue',
      () async {
        await db.saveLastPlayedTrack(mockSong, [mockSong]);
        expect(db.lastPlayedSong?.id, equals(mockSong.id));
        expect(db.lastPlayedQueue.length, equals(1));

        // Re-load stores to simulate cold app launch
        await db.switchUserScope(null);
        expect(db.lastPlayedSong?.id, equals(mockSong.id));
      },
    );

    test(
      'fetchOnlineTrending preserves user currentSong and does not overwrite with trending top song',
      () async {
        await db.saveLastPlayedTrack(mockSong, [mockSong]);
        playerManager.resetStateForTesting();

        // Simulate app opening and hydrating from storage
        db.notify();
        expect(playerManager.currentSong?.id, equals(mockSong.id));

        // Simulate online trending playlist loading
        await playerManager.fetchOnlineTrending();

        // currentSong must still be mockSong (the user's last played song)
        expect(playerManager.currentSong?.id, equals(mockSong.id));
      },
    );

    testWidgets(
      'ContinuePlayingSection is completely hidden when no track has been played/paused',
      (tester) async {
        await db.clearHistory();
        playerManager.resetStateForTesting();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ContinuePlayingSection()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must NOT render the 'Continue Playing' header
        expect(find.text('Continue Playing'), findsNothing);
        expect(find.text('Pick up where you left off'), findsNothing);
      },
    );

    testWidgets(
      'ContinuePlayingSection displays exactly the last played/paused song',
      (tester) async {
        await db.saveLastPlayedTrack(mockSong, [mockSong], 45000);
        playerManager.resetStateForTesting();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ContinuePlayingSection()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Continue Playing'), findsOneWidget);
        expect(find.text('Tum Hi Ho'), findsOneWidget);
        expect(db.lastPlayedPositionMs, equals(45000));
      },
    );

    test(
      'DatabaseService does not pick random history items when lastPlayedSong is null',
      () async {
        await db.clearHistory();
        // Add a history item without saving lastPlayedSong
        await db.addHistory(mockSong, syncToCloud: false);

        // Clear last played song explicitly
        await StorageEngine.removeItem('guest_last_played_song');
        await db.switchUserScope(null);

        // _loadLastPlayedTrack must NOT fallback to history
        expect(db.lastPlayedSong, isNull);
      },
    );
  });
}
