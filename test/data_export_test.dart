import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Data Export (exportAllDataJson) Unit Tests', () {
    late DatabaseService db;

    const favoriteSong = Song(
      id: 'export_fav_1',
      title: 'Export Favorite Song',
      artist: 'Export Fav Artist',
      duration: Duration(seconds: 195),
      audioUrl: 'https://example.com/fav.mp3',
      coverUrl: 'https://example.com/fav_art.jpg',
    );

    const historySong = Song(
      id: 'export_hist_1',
      title: 'Export History Song',
      artist: 'Export Hist Artist',
      duration: Duration(seconds: 240),
      audioUrl: 'https://example.com/hist.mp3',
      coverUrl: 'https://example.com/hist_art.jpg',
    );

    const downloadSong = Song(
      id: 'export_dl_1',
      title: 'Export Download Song',
      artist: 'Export DL Artist',
      duration: Duration(seconds: 180),
      audioUrl: 'https://example.com/dl.mp3',
      coverUrl: 'https://example.com/dl_art.jpg',
    );

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.deleteScopedLocalData('export_user_uid');
      await db.switchUserScope(null);
      await db.clearAllUserData();
    });

    test('add favorite + history + download -> export JSON contains them in active scope', () async {
      // 1. Add favorite
      await db.toggleFavorite(favoriteSong, syncToCloud: false);
      expect(db.isFavorite(favoriteSong.id), isTrue);

      // 2. Add history (non-incognito)
      await db.addHistory(historySong, syncToCloud: false);
      expect(db.history.length, equals(1));
      expect(db.history.first['songId'], equals(historySong.id));

      // 3. Add download
      await db.saveDownload(
        song: downloadSong,
        fileSize: '4.8 MB',
        localPath: '/storage/offline/export_dl_1.mp3',
      );
      expect(db.isDownloaded(downloadSong.id), isTrue);

      // 4. Add search query, playlist, and friend
      await db.addSearchQuery('Arijit Singh Hits');
      final playlist = await db.createPlaylist('My Export Playlist', syncToCloud: false);
      await db.addSongToPlaylist(playlist.id, favoriteSong, syncToCloud: false);
      await db.addFriend('friend@jumbomusic.app', name: 'Friend One');

      // 5. Generate export JSON
      final jsonString = await db.exportAllDataJson();
      expect(jsonString, isNotEmpty);

      final Map<String, dynamic> exportMap = jsonDecode(jsonString);

      // Verify header & scope
      expect(exportMap['app'], equals('Jumbo Music'));
      expect(exportMap['scope'], equals('guest'));
      expect(exportMap['exportedAt'], isNotNull);

      // Verify favorites
      final List<dynamic> favorites = exportMap['favorites'];
      expect(favorites.length, equals(1));
      expect(favorites.first['id'], equals(favoriteSong.id));
      expect(favorites.first['title'], equals('Export Favorite Song'));

      // Verify history
      final List<dynamic> history = exportMap['history'];
      expect(history.length, equals(1));
      expect(history.first['songId'], equals(historySong.id));
      expect(history.first['song']['title'], equals('Export History Song'));

      // Verify downloads
      final List<dynamic> downloads = exportMap['downloads'];
      expect(downloads.length, equals(1));
      expect(downloads.first['songId'], equals(downloadSong.id));
      expect(downloads.first['fileSize'], equals('4.8 MB'));
      expect(downloads.first['localPath'], equals('/storage/offline/export_dl_1.mp3'));

      // Verify search history
      final List<dynamic> searchHistory = exportMap['searchHistory'];
      expect(searchHistory, contains('Arijit Singh Hits'));

      // Verify custom playlists
      final List<dynamic> customPlaylists = exportMap['customPlaylists'];
      expect(customPlaylists.any((p) => p['title'] == 'My Export Playlist'), isTrue);

      // Verify friends
      final List<dynamic> friends = exportMap['friends'];
      expect(friends.any((f) => f['email'] == 'friend@jumbomusic.app'), isTrue);
    });

    test('logged in user export contains user-scoped favorites, history, and downloads', () async {
      await db.login(
        email: 'tester@jumbomusic.app',
        name: 'Tester User',
        uid: 'export_user_uid',
      );
      expect(db.currentScope, equals('user_export_user_uid'));
      expect(db.isLoggedIn, isTrue);

      // Add user-specific data
      await db.toggleFavorite(favoriteSong, syncToCloud: false);
      await db.addHistory(historySong, syncToCloud: false);
      await db.saveDownload(
        song: downloadSong,
        fileSize: '5.2 MB',
        localPath: '/storage/offline/user_dl.mp3',
      );

      final jsonString = await db.exportAllDataJson();
      final Map<String, dynamic> exportMap = jsonDecode(jsonString);

      expect(exportMap['scope'], equals('user_export_user_uid'));
      expect(exportMap['profile']['email'], equals('tester@jumbomusic.app'));
      expect(exportMap['profile']['isLoggedIn'], isTrue);

      final List<dynamic> favorites = exportMap['favorites'];
      expect(favorites.length, equals(1));
      expect(favorites.first['id'], equals(favoriteSong.id));

      final List<dynamic> history = exportMap['history'];
      expect(history.length, equals(1));
      expect(history.first['songId'], equals(historySong.id));

      final List<dynamic> downloads = exportMap['downloads'];
      expect(downloads.length, equals(1));
      expect(downloads.first['songId'], equals(downloadSong.id));

      // Verify version & summary
      expect(exportMap['version'], equals('2.0.0'));
      expect(exportMap['summary'], isNotNull);
      expect(exportMap['summary']['totalFavorites'], equals(1));
      expect(exportMap['summary']['totalDownloads'], equals(1));
      expect(exportMap['summary']['totalHistory'], equals(1));
    });
  });
}
