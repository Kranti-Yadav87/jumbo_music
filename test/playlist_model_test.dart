import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/playlist.dart';
import 'package:jumbo_music/models/song.dart';

void main() {
  group('Playlist Model Tests', () {
    test('Serializes and deserializes playlist correctly', () {
      const song = Song(
        id: 's_1',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        duration: Duration(seconds: 240),
        audioUrl: 'https://example.com/kesariya.mp3',
        coverUrl: 'https://example.com/cover.jpg',
      );

      final playlist = Playlist(
        id: 'pl_100',
        title: 'Bollywood Romance',
        description: 'Best love songs',
        coverUrl: 'https://example.com/cover.jpg',
        songIds: const ['s_1'],
        songs: const [song],
        type: PlaylistType.custom,
        isCollaborative: true,
        collaboratorNames: const ['User1', 'User2'],
      );

      final json = playlist.toJson();
      final fromJson = Playlist.fromJson(json);

      expect(fromJson.id, equals('pl_100'));
      expect(fromJson.title, equals('Bollywood Romance'));
      expect(fromJson.songIds.length, equals(1));
      expect(fromJson.songs.length, equals(1));
      expect(fromJson.songs.first.title, equals('Kesariya'));
      expect(fromJson.isCollaborative, isTrue);
      expect(fromJson.collaboratorNames.length, equals(2));
    });
  });
}
