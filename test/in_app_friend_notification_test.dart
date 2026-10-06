import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/friend_request.dart';
import 'package:jumbo_music/screens/friends/incoming_requests_section.dart';

void main() {
  group('Friend Request Model & Notification Tests', () {
    test('FriendRequest model serialization and initials derivation', () {
      final req = FriendRequest(
        id: 'req_123',
        fromUid: 'user_a',
        toUid: 'user_b',
        fromName: 'Priya Patel',
        fromEmail: 'priya@jumbo.app',
        toName: 'Suraj',
        toEmail: 'suraj@jumbo.app',
        status: FriendRequestStatus.pending,
        createdAt: DateTime(2026, 1, 15, 10, 30),
      );

      expect(req.fromInitials, equals('PP'));

      final json = req.toJson();
      expect(json['id'], equals('req_123'));
      expect(json['fromName'], equals('Priya Patel'));
      expect(json['status'], equals('pending'));

      final reconstructed = FriendRequest.fromJson(json);
      expect(reconstructed.id, equals('req_123'));
      expect(reconstructed.fromName, equals('Priya Patel'));
      expect(reconstructed.fromEmail, equals('priya@jumbo.app'));
      expect(reconstructed.status, equals(FriendRequestStatus.pending));
    });

    testWidgets(
      'IncomingRequestsSection renders requests with Accept and Decline actions',
      (tester) async {
        final requests = [
          FriendRequest(
            id: 'req_001',
            fromUid: 'uid_sender_1',
            toUid: 'uid_receiver',
            fromName: 'Rohan Mehra',
            fromEmail: 'rohan@jumbo.app',
            toName: 'Me',
            toEmail: 'me@jumbo.app',
            status: FriendRequestStatus.pending,
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: IncomingRequestsSection(requests: requests, isDark: true),
            ),
          ),
        );

        expect(find.text('Incoming Requests'), findsOneWidget);
        expect(find.text('Rohan Mehra'), findsOneWidget);
        expect(find.text('rohan@jumbo.app'), findsOneWidget);
        expect(find.text('Accept'), findsOneWidget);
        expect(find.byTooltip('Decline'), findsOneWidget);
      },
    );

    testWidgets('IncomingRequestsSection returns SizedBox.shrink when empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IncomingRequestsSection(requests: [], isDark: true),
          ),
        ),
      );

      expect(find.text('Incoming Requests'), findsNothing);
    });
  });
}
