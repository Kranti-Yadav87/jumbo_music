import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:jumbo_music/services/notification_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPermissionService Tests', () {
    late NotificationPermissionService service;

    setUp(() {
      service = NotificationPermissionService.instance;
      service.resetForTesting();
      NotificationPermissionService.mockTargetPlatform = TargetPlatform.android;
      NotificationPermissionService.mockStatusCheck = null;
      NotificationPermissionService.mockRequest = null;
      NotificationPermissionService.mockOpenSettings = null;
    });

    tearDown(() {
      NotificationPermissionService.mockTargetPlatform = null;
      NotificationPermissionService.mockStatusCheck = null;
      NotificationPermissionService.mockRequest = null;
      NotificationPermissionService.mockOpenSettings = null;
    });

    test('Initial state has not prompted', () {
      expect(service.hasPrompted, isFalse);
    });

    test('Does not request if already granted', () async {
      bool requestCalled = false;
      NotificationPermissionService.mockStatusCheck = () async =>
          PermissionStatus.granted;
      NotificationPermissionService.mockRequest = () async {
        requestCalled = true;
        return PermissionStatus.granted;
      };

      await service.requestNotificationPermissionIfNeeded();

      expect(service.hasPrompted, isTrue);
      expect(requestCalled, isFalse);
    });

    testWidgets('Shows rationale dialog and requests permission when denied', (
      tester,
    ) async {
      bool requestCalled = false;
      NotificationPermissionService.mockStatusCheck = () async =>
          PermissionStatus.denied;
      NotificationPermissionService.mockRequest = () async {
        requestCalled = true;
        return PermissionStatus.granted;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => service.requestNotificationPermissionIfNeeded(
                  context: context,
                ),
                child: const Text('Start Playback'),
              );
            },
          ),
        ),
      );

      // Tap button to initiate permission request
      await tester.tap(find.text('Start Playback'));
      await tester.pumpAndSettle();

      // Rationale dialog should appear
      expect(find.text('Media Controls'), findsOneWidget);
      expect(
        find.textContaining('Enable notifications so Jumbo Music can show'),
        findsOneWidget,
      );

      // Tap 'Continue' on rationale dialog
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(requestCalled, isTrue);
      expect(service.hasPrompted, isTrue);
    });

    testWidgets(
      'Shows open settings dialog when status is permanently denied',
      (tester) async {
        bool openSettingsCalled = false;
        NotificationPermissionService.mockStatusCheck = () async =>
            PermissionStatus.permanentlyDenied;
        NotificationPermissionService.mockOpenSettings = () async {
          openSettingsCalled = true;
          return true;
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => service
                      .requestNotificationPermissionIfNeeded(context: context),
                  child: const Text('Start Playback'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Start Playback'));
        await tester.pumpAndSettle();

        // Settings dialog should appear
        expect(find.text('Enable Notifications'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);

        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        expect(openSettingsCalled, isTrue);
      },
    );
  });
}
