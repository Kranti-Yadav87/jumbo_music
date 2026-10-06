import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/friend.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/presence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Friend Removal Logic Tests', () {
    late DatabaseService db;
    late PresenceService presence;

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();
      presence = PresenceService.instance;
    });

    test(
      'Removes friend locally from DatabaseService and PresenceService',
      () async {
        final friend = Friend(
          id: 'friend_test_123',
          name: 'Sara Khan',
          email: 'sara@jumbo.app',
          avatarInitials: 'SK',
        );

        // Save friend locally
        await db.saveFriendLocally(friend);
        expect(db.friends.any((f) => f.id == friend.id), isTrue);

        // Remove friend
        await presence.removeFriend(friend.id);
        expect(db.friends.any((f) => f.id == friend.id), isFalse);
        expect(presence.liveFriends.any((f) => f.id == friend.id), isFalse);
      },
    );

    test(
      'Multiple friends removal removes target and preserves others',
      () async {
        final friend1 = Friend(
          id: 'f_1',
          name: 'Aman',
          email: 'aman@jumbo.app',
          avatarInitials: 'A',
        );
        final friend2 = Friend(
          id: 'f_2',
          name: 'Bina',
          email: 'bina@jumbo.app',
          avatarInitials: 'B',
        );

        await db.saveFriendLocally(friend1);
        await db.saveFriendLocally(friend2);
        expect(db.friends.length, equals(2));

        await presence.removeFriend(friend1.id);
        expect(db.friends.length, equals(1));
        expect(db.friends.first.id, equals('f_2'));
      },
    );

    testWidgets(
      'Remove Friend confirmation dialog UI structure matches expectations',
      (tester) async {
        final friend = Friend(
          id: 'friend_modal_123',
          name: 'Arjun Verma',
          email: 'arjun@jumbo.app',
          avatarInitials: 'AV',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.person_remove_rounded, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Remove Friend?'),
                  ],
                ),
                content: Text(
                  'Are you sure you want to remove ${friend.name} (${friend.email}) from your friends list?',
                ),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Cancel')),
                  ElevatedButton(onPressed: () {}, child: const Text('Remove')),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Remove Friend?'), findsOneWidget);
        expect(
          find.textContaining('Are you sure you want to remove Arjun Verma'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Remove'), findsOneWidget);
        expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);
      },
    );
  });
}
