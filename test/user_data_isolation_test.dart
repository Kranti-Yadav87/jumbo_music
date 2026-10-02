import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/models/song.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Data Isolation Tests', () {
    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.deleteScopedLocalData('alice_123');
      await db.deleteScopedLocalData('alice_uid');
      await db.deleteScopedLocalData('bob_456');
      await db.deleteScopedLocalData('bob_uid');
      await db.switchUserScope(null);
      await db.clearAllUserData();
    });

    test('Guest and Authenticated User Data are strictly isolated', () async {
      // 1. In Guest Scope: add a favorite song
      await db.switchUserScope(null);
      expect(db.currentScope, equals('guest'));

      const guestSong = Song(
        id: 'song_guest_1',
        title: 'Guest Song',
        artist: 'Guest Artist',
        duration: Duration(seconds: 180),
        audioUrl: 'https://example.com/guest.mp3',
        coverUrl: '',
      );
      await db.toggleFavorite(guestSong, syncToCloud: false);
      expect(db.isFavorite('song_guest_1'), isTrue);
      expect(db.favoriteSongs.length, equals(1));

      // 2. Switch to User Alice Scope
      await db.switchUserScope('alice_123');
      expect(db.currentScope, equals('user_alice_123'));
      // Alice must NOT see Guest's favorite song
      expect(db.isFavorite('song_guest_1'), isFalse);
      expect(db.favoriteSongs, isEmpty);

      // Alice adds her own favorite song
      const aliceSong = Song(
        id: 'song_alice_1',
        title: 'Alice Track',
        artist: 'Alice Artist',
        duration: Duration(seconds: 200),
        audioUrl: 'https://example.com/alice.mp3',
        coverUrl: '',
      );
      await db.toggleFavorite(aliceSong, syncToCloud: false);
      expect(db.isFavorite('song_alice_1'), isTrue);

      // 3. Switch to User Bob Scope
      await db.switchUserScope('bob_456');
      expect(db.currentScope, equals('user_bob_456'));
      // Bob must NOT see Alice's or Guest's favorite song
      expect(db.isFavorite('song_guest_1'), isFalse);
      expect(db.isFavorite('song_alice_1'), isFalse);
      expect(db.favoriteSongs, isEmpty);

      // 4. Switch back to Alice: Alice's data is safely preserved
      await db.switchUserScope('alice_123');
      expect(db.isFavorite('song_alice_1'), isTrue);
      expect(db.isFavorite('song_guest_1'), isFalse);

      // 5. Switch back to Guest: Guest data is safely preserved
      await db.switchUserScope(null);
      expect(db.isFavorite('song_guest_1'), isTrue);
      expect(db.isFavorite('song_alice_1'), isFalse);
    });

    test('Custom Playlists are isolated per user scope', () async {
      // Create playlist as Alice
      await db.switchUserScope('alice_uid');
      final alicePl = await db.createPlaylist('Alice Hits', syncToCloud: false);
      expect(db.customPlaylists.length, equals(1));
      expect(db.customPlaylists.first.title, equals('Alice Hits'));

      // Switch to Bob
      await db.switchUserScope('bob_uid');
      expect(db.customPlaylists, isEmpty);

      final bobPl = await db.createPlaylist('Bob Rock', syncToCloud: false);
      expect(bobPl.title, equals('Bob Rock'));
      expect(db.customPlaylists.length, equals(1));
      expect(db.customPlaylists.first.title, equals('Bob Rock'));

      // Switch to Guest
      await db.switchUserScope(null);
      expect(db.customPlaylists, isEmpty);

      // Switch back to Alice: Alice's playlist remains intact
      await db.switchUserScope('alice_uid');
      expect(db.customPlaylists.length, equals(1));
      expect(db.customPlaylists.first.id, equals(alicePl.id));
    });

    test('Listening history is scoped and respects incognito mode', () async {
      await db.switchUserScope('alice_uid');
      await db.updateSetting('incognitoMode', false);

      const song = Song(
        id: 'track_history_1',
        title: 'History Track',
        artist: 'Singer',
        duration: Duration(seconds: 150),
        audioUrl: '',
        coverUrl: '',
      );

      await db.addHistory(song, syncToCloud: false);
      expect(db.history.length, equals(1));
      expect(db.history.first['songId'], equals('track_history_1'));

      // Test incognito mode
      await db.updateSetting('incognitoMode', true);
      const incognitoSong = Song(
        id: 'track_secret',
        title: 'Secret Track',
        artist: 'Secret',
        duration: Duration(seconds: 120),
        audioUrl: '',
        coverUrl: '',
      );
      await db.addHistory(incognitoSong, syncToCloud: false);
      expect(db.history.length, equals(1)); // Should not increase
    });
  });
}
