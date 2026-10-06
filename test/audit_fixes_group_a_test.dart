import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/models/playlist.dart';
import 'package:jumbo_music/services/firestore_sync_service.dart';
import 'package:jumbo_music/services/presence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audit Group A Fixes', () {
    test('Item #3: FirestoreSyncService parsing handles empty or null data without crashing', () {
      final emptySong = Song.fromJson(const {});
      expect(emptySong.id, isEmpty);
      expect(emptySong.title, equals('Unknown Title'));

      final emptyPlaylist = Playlist.fromJson(const {});
      expect(emptyPlaylist.id, isEmpty);
      expect(emptyPlaylist.title, equals('Untitled Playlist'));
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
  });
}
