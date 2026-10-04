import 'dart:async';
import 'package:flutter/foundation.dart';

/// Centralized crash and error reporting service.
/// Captures Flutter widget errors, async zone uncaught exceptions,
/// and provides ready hooks for Firebase Crashlytics or Sentry.
class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;
  static final List<String> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 100;

  /// Initialize global Flutter & PlatformDispatcher error boundaries
  static void init() {
    if (_initialized) return;
    _initialized = true;

    // 1. Capture Flutter framework / rendering errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString() ?? 'Flutter Framework Error',
        fatal: false,
      );
    };

    // 2. Capture unhandled platform / asynchronous exceptions
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(
        error,
        stack,
        reason: 'Unhandled Platform Asynchronous Error',
        fatal: true,
      );
      return true; // Marked as handled
    };
  }

  /// Run app inside error-guarded zone
  static Future<void> runWithCrashReporting(
    FutureOr<void> Function() appRunner,
  ) async {
    init();
    await runZonedGuarded(
      () async {
        await appRunner();
      },
      (error, stack) {
        recordError(
          error,
          stack,
          reason: 'Root Zone Uncaught Exception',
          fatal: true,
        );
      },
    );
  }

  /// Log a breadcrumb for debugging timeline
  static void log(String message) {
    final entry = '[${DateTime.now().toIso8601String()}] $message';
    _breadcrumbs.add(entry);
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
    if (kDebugMode) {
      debugPrint('[CrashReporting] $entry');
    }
  }

  /// Record non-fatal or fatal error with stack trace
  static void recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) {
    final errorMsg = '💥 Error [fatal=$fatal, reason=$reason]: $exception';
    if (kDebugMode) {
      debugPrint(errorMsg);
      if (stack != null) {
        debugPrint(stack.toString());
      }
    }
    // Note: When Firebase Crashlytics is configured with google-services.json / GoogleService-Info.plist,
    // FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal)
    // can be directly activated here without changing any caller code.
  }

  /// Set user ID for crash reports
  static void setUserIdentifier(String userId) {
    log('User session set: $userId');
  }

  /// Clear user ID on logout
  static void clearUserIdentifier() {
    log('User session cleared');
  }
}
