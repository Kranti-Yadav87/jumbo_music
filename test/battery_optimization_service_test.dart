import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/battery_optimization_service.dart';
import 'package:jumbo_music/widgets/home/background_playback_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryOptimizationService Unit Tests', () {
    tearDown(() {
      BatteryOptimizationService.mockIsIgnored = null;
    });

    test('Singleton instance returns identical instance', () {
      final s1 = BatteryOptimizationService.instance;
      final s2 = BatteryOptimizationService();
      expect(identical(s1, s2), isTrue);
    });

    test(
      'checkOptimizationStatus honors mock override when not ignored',
      () async {
        final service = BatteryOptimizationService.instance;
        BatteryOptimizationService.mockIsIgnored = false;

        final isIgnored = await service.checkOptimizationStatus();
        expect(isIgnored, isFalse);
        expect(service.isOptimizationIgnored, isFalse);
        expect(service.hasChecked, isTrue);
      },
    );

    test(
      'requestIgnoreBatteryOptimization updates state and notifies',
      () async {
        final service = BatteryOptimizationService.instance;
        BatteryOptimizationService.mockIsIgnored = false;
        await service.checkOptimizationStatus();
        expect(service.isOptimizationIgnored, isFalse);

        bool notified = false;
        service.addListener(() => notified = true);

        final success = await service.requestIgnoreBatteryOptimization();
        expect(success, isTrue);
        expect(service.isOptimizationIgnored, isTrue);
        expect(notified, isTrue);
      },
    );
  });

  group('BackgroundPlaybackBanner Widget Tests', () {
    tearDown(() {
      BatteryOptimizationService.mockIsIgnored = null;
    });

    testWidgets('Renders banner when battery optimization is restricted', (
      tester,
    ) async {
      BatteryOptimizationService.mockIsIgnored = false;
      await BatteryOptimizationService.instance.checkOptimizationStatus();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BackgroundPlaybackBanner())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Uninterrupted Background Play'), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);
    });

    testWidgets('Hides banner when battery optimization is already ignored', (
      tester,
    ) async {
      BatteryOptimizationService.mockIsIgnored = true;
      await BatteryOptimizationService.instance.checkOptimizationStatus();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BackgroundPlaybackBanner())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Uninterrupted Background Play'), findsNothing);
    });
  });
}
