import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/privacy_security_service.dart';
import 'package:jumbo_music/models/song.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Privacy, Incognito Mode & GDPR Security Suite Tests', () {
    late DatabaseService db;
    late PrivacySecurityService privacy;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();
      await db.updateSetting('incognitoMode', false);
      privacy = PrivacySecurityService();
    });

    tearDown(() async {
      await db.updateSetting('incognitoMode', false);
    });

    test(
      'Incognito mode suppresses playback history and search history',
      () async {
        // 1. When incognito is FALSE
        if (privacy.isIncognitoMode) {
          privacy.toggleIncognitoMode();
        }
        expect(privacy.isIncognitoMode, isFalse);

        final song = Song(
          id: 'priv_song_1',
          title: 'Public History Track',
          artist: 'Artist Test',
          audioUrl: 'https://example.com/audio.mp3',
          coverUrl: 'https://example.com/cover.jpg',
          duration: const Duration(seconds: 180),
        );

        await db.addHistory(song);
        await db.addSearchQuery('Bollywood Hits');

        expect(db.history.any((h) => h['songId'] == 'priv_song_1'), isTrue);
        expect(db.searchHistory.contains('Bollywood Hits'), isTrue);

        // 2. Toggle incognito to TRUE
        privacy.toggleIncognitoMode();
        expect(privacy.isIncognitoMode, isTrue);

        final incognitoSong = Song(
          id: 'incognito_song_2',
          title: 'Secret Incognito Track',
          artist: 'Secret Artist',
          audioUrl: 'https://example.com/secret.mp3',
          coverUrl: 'https://example.com/cover.jpg',
          duration: const Duration(seconds: 180),
        );

        await db.addHistory(incognitoSong);
        await db.addSearchQuery('Hidden Query');

        // Should NOT be added
        expect(
          db.history.any((h) => h['songId'] == 'incognito_song_2'),
          isFalse,
        );
        expect(db.searchHistory.contains('Hidden Query'), isFalse);
      },
    );

    test('exportUserDataAsJson produces valid GDPR structured JSON', () {
      final jsonStr = privacy.exportUserDataAsJson(
        favoriteIds: ['fav_1', 'fav_2'],
        downloadedSongIds: ['dl_1'],
        playlistCount: 3,
      );

      final Map<String, dynamic> parsed = jsonDecode(jsonStr);
      expect(parsed['app'], equals('Jumbo Music'));
      expect(parsed['user_data'], isNotNull);
      expect(parsed['user_data']['favorites_count'], equals(2));
      expect(parsed['user_data']['downloaded_count'], equals(1));
      expect(parsed['user_data']['custom_playlists_count'], equals(3));
      expect(parsed['privacy_guarantee'], isNotNull);
    });
  });
}
