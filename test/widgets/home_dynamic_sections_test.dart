import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/data/music_repository.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/music_api_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/widgets/home/search_inspired_section.dart';
import 'package:jumbo_music/widgets/home/featured_playlists_section.dart';
import 'package:jumbo_music/widgets/home/romance_section.dart';

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

    testWidgets('RomanceSection renders header and essentials', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: RomanceSection())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Soulful Romance ❤️'), findsOneWidget);
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
  });
}
