import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/crash_reporting_service.dart';

void main() {
  setUp(CrashReportingService.resetForTesting);

  group('buildPayload', () {
    test(
      'truncates oversized fields to the limits enforced by firestore.rules',
      () {
        final payload = CrashReportingService.buildPayload(
          exception: 'x' * 5000,
          stack: StackTrace.fromString('s' * 9000),
          reason: 'r' * 1000,
          fatal: true,
          platform: 'android',
          appVersion: '2.0.0',
          userId: 'abc',
          breadcrumbs: List.generate(100, (i) => 'crumb-$i ${'b' * 100}'),
        );
        expect(
          (payload['message'] as String).length,
          CrashReportingService.maxMessageLength,
        );
        expect(
          (payload['stack'] as String).length,
          CrashReportingService.maxStackLength,
        );
        expect(
          (payload['reason'] as String).length,
          CrashReportingService.maxReasonLength,
        );
        expect(
          (payload['breadcrumbs'] as String).length,
          lessThanOrEqualTo(CrashReportingService.maxBreadcrumbLength),
        );
        expect(payload['fatal'], true);
        expect(payload['uid'], 'abc');
      },
    );

    test('only contains keys allowed by the firestore rule', () {
      final payload = CrashReportingService.buildPayload(
        exception: 'boom',
        fatal: false,
        platform: 'web',
        appVersion: '2.0.0',
      );
      const allowed = {
        'message',
        'stack',
        'reason',
        'fatal',
        'platform',
        'appVersion',
        'uid',
        'breadcrumbs',
      };
      expect(payload.keys.toSet().difference(allowed), isEmpty);
    });

    test('keeps only the most recent breadcrumbs', () {
      final payload = CrashReportingService.buildPayload(
        exception: 'boom',
        fatal: false,
        platform: 'web',
        appVersion: '2.0.0',
        breadcrumbs: List.generate(50, (i) => 'c$i'),
      );
      final text = payload['breadcrumbs'] as String;
      expect(text.contains('c49'), isTrue);
      expect(text.contains('c0\n'), isFalse);
    });
  });

  group('shouldSend', () {
    test('de-duplicates identical errors', () {
      expect(CrashReportingService.shouldSend('a|b'), isTrue);
      expect(CrashReportingService.shouldSend('a|b'), isFalse);
    });

    test('stops after the per-session cap', () {
      for (var i = 0; i < CrashReportingService.maxReportsPerSession; i++) {
        expect(CrashReportingService.shouldSend('sig-$i'), isTrue);
      }
      expect(CrashReportingService.shouldSend('one-too-many'), isFalse);
    });
  });

  group('swallow / recordError', () {
    test('swallow leaves a breadcrumb and never throws', () {
      CrashReportingService.swallow(Exception('offline'), 'test:1');
      expect(
        CrashReportingService.breadcrumbsForTesting.last,
        contains('swallowed @ test:1'),
      );
    });

    test('recordError is safe in tests (remote reporting is off)', () {
      expect(CrashReportingService.remoteReportingEnabled, isFalse);
      CrashReportingService.recordError(
        StateError('x'),
        StackTrace.current,
        reason: 'unit test',
      );
      expect(CrashReportingService.breadcrumbsForTesting, isNotEmpty);
    });
  });
}
