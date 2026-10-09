import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/friend.dart';
import 'package:jumbo_music/models/playlist.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Collaborative Playlist & Duo Blend Tests', () {
    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();
    });

    test(
      'createSharedBlendPlaylist creates collaborative duo playlist',
      () async {
        final friend = Friend(
          id: 'friend_test_1',
          name: 'Rohan Sharma',
          email: 'rohan@example.com',
          isOnline: true,
        );

        final starterSong = Song(
          id: 's_collab_1',
          title: 'Duo Collab Song',
          artist: 'Duo Artist',
          audioUrl: 'https://example.com/song.mp3',
          coverUrl: 'https://example.com/cover.jpg',
          duration: const Duration(seconds: 240),
        );

        final playlist = await db.createSharedBlendPlaylist(
          title: 'Summer Vibes Blend',
          friend: friend,
          starterSongs: [starterSong],
        );

        expect(playlist.title, equals('Summer Vibes Blend'));
        expect(playlist.isCollaborative, isTrue);
        expect(playlist.friendEmail, equals('rohan@example.com'));
        expect(playlist.type, equals(PlaylistType.sharedBlend));
        expect(playlist.songIds.contains('s_collab_1'), isTrue);
        expect(playlist.songs.length, equals(1));

        // Verify customPlaylists contains this shared playlist
        final inStore = db.getPlaylistById(playlist.id);
        expect(inStore, isNotNull);
        expect(inStore!.title, equals('Summer Vibes Blend'));

        // Add second song to shared playlist
        final secondSong = Song(
          id: 's_collab_2',
          title: 'Second Blend Song',
          artist: 'Second Artist',
          audioUrl: 'https://example.com/song2.mp3',
          coverUrl: 'https://example.com/cover2.jpg',
          duration: const Duration(seconds: 210),
        );

        await db.addSongToSharedPlaylist(playlist.id, secondSong);

        final updated = db.getPlaylistById(playlist.id);
        expect(updated, isNotNull);
        expect(updated!.songIds.contains('s_collab_2'), isTrue);
        expect(updated.songs.length, equals(2));
      },
    );
  });
}
