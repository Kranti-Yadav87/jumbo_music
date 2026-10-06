import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore Security Rules Verification', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'firestore.rules must exist at project root',
      );
      rulesContent = file.readAsStringSync();
    });

    test(
      'Item #1: match /app_feedback/{feedbackId} write-only rule is defined with schema constraints',
      () {
        expect(rulesContent, contains('match /app_feedback/{feedbackId}'));
        expect(rulesContent, contains('request.resource.data.rating is int'));
        expect(rulesContent, contains('request.resource.data.rating >= 1'));
        expect(rulesContent, contains('request.resource.data.rating <= 5'));
        expect(
          rulesContent,
          contains('request.resource.data.category.size() <= 50'),
        );
        expect(
          rulesContent,
          contains('request.resource.data.message.size() <= 2000'),
        );
        expect(
          rulesContent,
          contains('request.resource.data.createdAt == request.time'),
        );
        expect(rulesContent, contains('allow read, update, delete: if false;'));
      },
    );

    test(
      'Item #8: match /shared_playlists/{playlistId} update rule protects ownerId and collaboratorEmails',
      () {
        expect(rulesContent, contains('match /shared_playlists/{playlistId}'));
        expect(
          rulesContent,
          contains('request.resource.data.ownerId == resource.data.ownerId'),
        );
        expect(
          rulesContent,
          contains(
            'request.resource.data.get(\'collaboratorEmails\', []) == resource.data.get(\'collaboratorEmails\', [])',
          ),
        );
      },
    );
  });
}
