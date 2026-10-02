import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/friend.dart';

void main() {
  group('Presence & Friend Model Tests', () {
    test('Serializes and deserializes Friend with live presence', () {
      final friend = Friend(
        id: 'u_12345',
        name: 'Aman Sharma',
        email: 'aman@jumbo.app',
        avatarInitials: 'AS',
        currentSongTitle: 'Kesariya',
        currentSongArtist: 'Arijit Singh',
        currentSongId: 'kesariya_1',
        isOnline: true,
        isListening: true,
      );

      final json = friend.toJson();
      expect(json['name'], 'Aman Sharma');
      expect(json['isListening'], true);
      expect(json['currentSongTitle'], 'Kesariya');

      final reconstructed = Friend.fromJson(json);
      expect(reconstructed.id, 'u_12345');
      expect(reconstructed.name, 'Aman Sharma');
      expect(reconstructed.isListening, true);
      expect(reconstructed.initials, 'AS');
    });

    test('Derives initials correctly when avatarInitials is empty', () {
      final friend1 = Friend(id: '1', name: 'John Doe', email: 'john@doe.com');
      expect(friend1.initials, 'JD');

      final friend2 = Friend(id: '2', name: 'Single', email: 's@doe.com');
      expect(friend2.initials, 'S');

      final friend3 = Friend(id: '3', name: '', email: 'emailonly@doe.com');
      expect(friend3.initials, 'E');
    });
  });
}
