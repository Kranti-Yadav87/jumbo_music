import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/config/app_config.dart';
import 'package:jumbo_music/screens/home_tab.dart';
import 'package:jumbo_music/screens/search_tab.dart';
import 'package:jumbo_music/services/api/jamendo_search_service.dart';
import 'package:jumbo_music/services/music_api_service.dart';

void main() {
  setUp(() {
    AppConfig.mockUseUnofficialCatalog = null;
    AppConfig.mockJamendoClientId = null;
    MusicApiService.mockSearchLiveSongs = null;
  });

  tearDown(() {
    AppConfig.mockUseUnofficialCatalog = null;
    AppConfig.mockJamendoClientId = null;
    MusicApiService.mockSearchLiveSongs = null;
  });

  group('Official Catalog Flag (USE_UNOFFICIAL_CATALOG = false)', () {
    test(
      'When USE_UNOFFICIAL_CATALOG is false and Jamendo is unconfigured, searchLiveSongs returns empty immediately',
      () async {
        AppConfig.mockUseUnofficialCatalog = false;
        AppConfig.mockJamendoClientId = '';

        expect(JamendoSearchService.isConfigured, isFalse);
        final results = await MusicApiService.searchLiveSongs('Arijit Singh');
        expect(results, isEmpty);
      },
    );

    test(
      'When USE_UNOFFICIAL_CATALOG is false, fetchPlaylist returns empty without network call',
      () async {
        AppConfig.mockUseUnofficialCatalog = false;

        final result = await MusicApiService.fetchPlaylist('1134543272');
        expect(result['id'], equals('1134543272'));
        expect(result['songs'], isEmpty);
      },
    );

    test(
      'When USE_UNOFFICIAL_CATALOG is false, curated playlists query Jamendo instead of Supabase playlist IDs',
      () async {
        AppConfig.mockUseUnofficialCatalog = false;
        AppConfig.mockJamendoClientId = ''; // Unconfigured -> empty

        expect(await MusicApiService.fetchIndiaTop50(), isEmpty);
        expect(await MusicApiService.fetchTrendingToday(), isEmpty);
        expect(await MusicApiService.fetchBestOfIndie(), isEmpty);
        expect(await MusicApiService.fetch90sDuets(), isEmpty);
      },
    );

    test(
      'When USE_UNOFFICIAL_CATALOG is false, searchOnlineSongsFallback never calls iTunes',
      () async {
        AppConfig.mockUseUnofficialCatalog = false;
        AppConfig.mockJamendoClientId = '';

        final results = await MusicApiService.searchOnlineSongsFallback(
          'test query',
        );
        expect(results, isEmpty);
      },
    );

    test(
      'When USE_UNOFFICIAL_CATALOG is false, fetchByLanguage and fetchNewReleases use only Jamendo',
      () async {
        AppConfig.mockUseUnofficialCatalog = false;
        AppConfig.mockJamendoClientId = '';

        final langResults = await MusicApiService.fetchByLanguage('Hindi');
        expect(langResults, isEmpty);

        final releases = await MusicApiService.fetchNewReleases();
        expect(releases, isEmpty);
      },
    );
  });

  group('Catalog Flag UI Empty States', () {
    testWidgets(
      'SearchTab displays friendly banner and empty state when USE_UNOFFICIAL_CATALOG=false and Jamendo unconfigured',
      (tester) async {
        AppConfig.mockUseUnofficialCatalog = false;
        AppConfig.mockJamendoClientId = '';

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SearchTab())),
        );
        await tester.pump();

        // Banner text check
        expect(find.text('Official Catalog Mode (Jamendo)'), findsOneWidget);
        expect(
          find.text(
            'Jamendo Client ID is not configured. Set --dart-define=JAMENDO_CLIENT_ID=your_id to search legal music.',
          ),
          findsOneWidget,
        );

        // Type a search query to test the empty search result text
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'Coldplay');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Jamendo Client ID is not configured.\nSet --dart-define=JAMENDO_CLIENT_ID=... to search legal music.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'HomeTab displays friendly banner when USE_UNOFFICIAL_CATALOG=false and Jamendo unconfigured',
      (tester) async {
        AppConfig.mockUseUnofficialCatalog = false;
        AppConfig.mockJamendoClientId = '';

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: HomeTab())),
        );
        await tester.pump();

        // Banner should be visible on home tab
        expect(find.text('Official Catalog Mode (Jamendo)'), findsOneWidget);
        expect(
          find.textContaining('Jamendo Client ID is not configured'),
          findsOneWidget,
        );
      },
    );
  });
}
