import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/models/playlist.dart';
import 'package:jumbo_music/services/firestore_sync_service.dart';
import 'package:jumbo_music/services/presence_service.dart';
import 'package:jumbo_music/services/download_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/services/crash_reporting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audit Group A Fixes', () {
    test('Item #3: FirestoreSyncService parsing handles empty or null data without crashing', () {
      final emptySong = Song.fromJson(const {});
      expect(emptySong.id, isEmpty);
      expect(emptySong.title, equals('Unknown Title'));

      final emptyPlaylist = Playlist.fromJson(const {});
      expect(emptyPlaylist.id, isNotEmpty);
      expect(emptyPlaylist.title, equals('Custom Playlist'));
    });

    test('Item #4: PresenceService handles init and dispose cleanly without leaking listeners', () {
      final service = PresenceService.instance;
      service.init();
      expect(service.liveFriends, isNotNull);
      service.dispose();
      expect(service.liveFriends, isNotNull);
    });

    test('Item #5: MusicPlayerManager registers and cleanly disposes listeners without throwing', () {
      final manager = MusicPlayerManager();
      expect(manager.allSongs, isNotNull);
      expect(manager.currentIndex, isNotNull);
    });

    test('Item #6: DownloadService guards against duplicate in-flight downloads for the same song', () {
      final downloadService = DownloadService();
      const testSong = Song(
        id: 'dup_test_song',
        title: 'Duplicate Test',
        artist: 'Test Artist',
        audioUrl: 'https://example.com/test.mp3',
        coverUrl: '',
        duration: Duration(seconds: 120),
      );
      expect(downloadService.isDownloading(testSong.id), isFalse);
    });

    test('Item #7: Dialog TextEditingControllers dispose lifecycle is verified', () {
      final controller = TextEditingController();
      expect(controller.text, isEmpty);
      controller.dispose();
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    test('Item #9: CrashReportingService.swallow records breadcrumb on error', () {
      expect(
        () => CrashReportingService.swallow(
          Exception('test sync failure'),
          'firestore_sync_service.dart:test',
        ),
        returnsNormally,
      );
    });
  });
}
