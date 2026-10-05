import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/friend.dart';
import 'package:jumbo_music/models/friend_request.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/friend_request_service.dart';
import 'package:jumbo_music/services/storage/storage_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FriendRequest Model Tests', () {
    test('serializes and deserializes FriendRequest correctly', () {
      final now = DateTime(2026, 10, 5, 12, 0);
      final request = FriendRequest(
        id: 'req_123',
        fromUid: 'user_a',
        toUid: 'user_b',
        status: FriendRequestStatus.pending,
        createdAt: now,
        fromName: 'Alice Smith',
        fromEmail: 'alice@example.com',
        toName: 'Bob Jones',
        toEmail: 'bob@example.com',
      );

      final json = request.toJson();
      expect(json['id'], equals('req_123'));
      expect(json['fromUid'], equals('user_a'));
      expect(json['toUid'], equals('user_b'));
      expect(json['status'], equals('pending'));
      expect(json['fromName'], equals('Alice Smith'));
      expect(json['fromEmail'], equals('alice@example.com'));

      final fromJson = FriendRequest.fromJson(json);
      expect(fromJson.id, equals('req_123'));
      expect(fromJson.fromUid, equals('user_a'));
      expect(fromJson.toUid, equals('user_b'));
      expect(fromJson.status, equals(FriendRequestStatus.pending));
      expect(fromJson.fromName, equals('Alice Smith'));
      expect(fromJson.fromEmail, equals('alice@example.com'));
      expect(fromJson.fromInitials, equals('AS'));
    });

    test('fromInitials handles various name and email formats', () {
      final req1 = FriendRequest(
        id: '1',
        fromUid: 'u1',
        toUid: 'u2',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        fromName: 'Kranti Yadav',
      );
      expect(req1.fromInitials, equals('KY'));

      final req2 = FriendRequest(
        id: '2',
        fromUid: 'u1',
        toUid: 'u2',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        fromName: 'SingleName',
      );
      expect(req2.fromInitials, equals('S'));

      final req3 = FriendRequest(
        id: '3',
        fromUid: 'u1',
        toUid: 'u2',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        fromEmail: 'testuser@jumbo.com',
      );
      expect(req3.fromInitials, equals('T'));

      final req4 = FriendRequest(
        id: '4',
        fromUid: 'u1',
        toUid: 'u2',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(req4.fromInitials, equals('?'));
    });

    test('FriendRequestStatus parses correctly', () {
      expect(
        FriendRequestStatus.fromString('pending'),
        equals(FriendRequestStatus.pending),
      );
      expect(
        FriendRequestStatus.fromString('accepted'),
        equals(FriendRequestStatus.accepted),
      );
      expect(
        FriendRequestStatus.fromString('declined'),
        equals(FriendRequestStatus.declined),
      );
      expect(
        FriendRequestStatus.fromString('unknown_status'),
        equals(FriendRequestStatus.pending),
      );
    });
  });

  group('FriendRequestService Unit Tests', () {
    late FriendRequestService service;
    late DatabaseService db;

    setUp(() async {
      StorageEngine.inMemoryOnly = true;
      StorageEngine.clearMemoryStorage();

      db = DatabaseService.instance;
      await db.init();
      await db.deleteScopedLocalData('test_current_uid');
      await db.clearAllUserData();

      FriendRequestService.resetInstance();
      service = FriendRequestService.instance;
    });

    tearDown(() {
      StorageEngine.clearMemoryStorage();
      StorageEngine.inMemoryOnly = false;
      FriendRequestService.resetInstance();
    });

    test('sendFriendRequest throws when email is empty or invalid', () async {
      expect(() => service.sendFriendRequest(''), throwsA(isA<Exception>()));
      expect(
        () => service.sendFriendRequest('invalid-email'),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'sendFriendRequest throws when not logged in or in guest mode',
      () async {
        // 1. Not logged in
        expect(db.isLoggedIn, isFalse);
        expect(
          () => service.sendFriendRequest('friend@example.com'),
          throwsA(
            predicate(
              (e) => e.toString().contains(
                'You must be signed in with an account',
              ),
            ),
          ),
        );

        // 2. In guest mode
        await db.loginAsGuest();
        expect(db.isGuest, isTrue);
        expect(
          () => service.sendFriendRequest('friend@example.com'),
          throwsA(
            predicate(
              (e) => e.toString().contains(
                'You must be signed in with an account',
              ),
            ),
          ),
        );
      },
    );

    test('sendFriendRequest throws when sending request to self', () async {
      await db.login(
        email: 'user@jumbomusic.app',
        name: 'User One',
        uid: 'user_1',
      );

      expect(
        () => service.sendFriendRequest('user@jumbomusic.app'),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              'cannot send a friend request to yourself',
            ),
          ),
        ),
      );
    });

    test(
      'sendFriendRequest throws when recipient is already a friend',
      () async {
        await db.login(
          email: 'user@jumbomusic.app',
          name: 'User One',
          uid: 'user_1',
        );

        await db.saveFriendLocally(
          Friend(
            id: 'friend_2',
            name: 'Friend Two',
            email: 'friend2@jumbomusic.app',
          ),
        );

        service.mockSearchUser = (email) async {
          return Friend(
            id: 'friend_2',
            name: 'Friend Two',
            email: 'friend2@jumbomusic.app',
          );
        };

        expect(
          () => service.sendFriendRequest('friend2@jumbomusic.app'),
          throwsA(
            predicate(
              (e) => e.toString().contains('already in your friends list'),
            ),
          ),
        );
      },
    );

    test(
      'acceptFriendRequest adds friend locally and removes from incoming list',
      () async {
        await db.login(
          email: 'recipient@jumbomusic.app',
          name: 'Recipient User',
          uid: 'user_recipient',
        );

        final request = FriendRequest(
          id: 'req_test_1',
          fromUid: 'user_sender',
          toUid: 'user_recipient',
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now(),
          fromName: 'Sender User',
          fromEmail: 'sender@jumbomusic.app',
        );

        service.setMockIncomingRequests([request]);
        expect(service.incomingRequests.length, equals(1));

        bool acceptMockCalled = false;
        service.mockAcceptRequest = (req) async {
          acceptMockCalled = true;
          await db.saveFriendLocally(
            Friend(
              id: req.fromUid,
              name: req.fromName,
              email: req.fromEmail,
              avatarInitials: req.fromInitials,
            ),
          );
          service.setMockIncomingRequests([]);
        };

        await service.acceptFriendRequest(request);

        expect(acceptMockCalled, isTrue);
        expect(service.incomingRequests, isEmpty);
        expect(db.friends.any((f) => f.id == 'user_sender'), isTrue);
      },
    );

    test(
      'declineFriendRequest updates status and removes from incoming list',
      () async {
        final request = FriendRequest(
          id: 'req_test_2',
          fromUid: 'user_sender_2',
          toUid: 'user_recipient',
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now(),
          fromName: 'Declined Sender',
          fromEmail: 'declined@jumbomusic.app',
        );

        service.setMockIncomingRequests([request]);
        expect(service.incomingRequests.length, equals(1));

        bool declineMockCalled = false;
        service.mockDeclineRequest = (req) async {
          declineMockCalled = true;
          service.setMockIncomingRequests([]);
        };

        await service.declineFriendRequest(request);

        expect(declineMockCalled, isTrue);
        expect(service.incomingRequests, isEmpty);
        expect(db.friends.any((f) => f.id == 'user_sender_2'), isFalse);
      },
    );
  });
}
