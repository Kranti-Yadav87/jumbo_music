import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Centralized crash and error reporting.
///
/// * Captures Flutter framework errors, platform async errors and root-zone
///   errors (see [runWithCrashReporting]).
/// * Keeps a ring buffer of breadcrumbs (also fed by [swallow], which replaces
///   the old silent `catch (_) {}` blocks).
/// * In release builds, sends a compact, size-limited report to the
///   `client_errors` Firestore collection (write-only, see firestore.rules).
///   Read them in Firebase console > Firestore Database > client_errors.
///
/// Reporting is rate-limited and de-duplicated so a crash loop can never
/// flood Firestore, and it can never throw back into the app.
class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;
  static final List<String> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 100;

  // ---- remote reporting limits -------------------------------------------
  static const int maxReportsPerSession = 15;
  static const int maxMessageLength = 500;
  static const int maxStackLength = 3000;
  static const int maxReasonLength = 200;
  static const int maxBreadcrumbLength = 2000;
  static const int breadcrumbsPerReport = 20;

  static final Set<String> _sentSignatures = <String>{};
  static int _sentCount = 0;
  static String? _userId;

  /// Remote reporting is on for release builds only (never debug/test).
  /// Override with `--dart-define=REPORT_ERRORS=true|false`.
  static const bool _reportOverride = bool.hasEnvironment('REPORT_ERRORS');
  static const bool _reportOverrideValue = bool.fromEnvironment(
    'REPORT_ERRORS',
  );
  static bool get remoteReportingEnabled =>
      _reportOverride ? _reportOverrideValue : kReleaseMode;

  /// Initialize global Flutter & PlatformDispatcher error boundaries.
  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString() ?? 'Flutter Framework Error',
        fatal: false,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(
        error,
        stack,
        reason: 'Unhandled Platform Asynchronous Error',
        fatal: true,
      );
      return true;
    };
  }

  /// Run app inside an error-guarded zone.
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

  /// Log a breadcrumb for the debugging timeline.
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

  /// For *expected / recoverable* failures that the app handles on its own
  /// (offline, storage unavailable, optional feature missing). It never
  /// uploads anything, but leaves a breadcrumb so the failure shows up in the
  /// timeline of any later crash report instead of vanishing silently.
  static void swallow(Object error, String where) {
    log('swallowed @ $where: ${_truncate(error.toString(), 160)}');
  }

  /// Record a non-fatal or fatal error with stack trace.
  static void recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) {
    try {
      if (kDebugMode) {
        debugPrint('Error [fatal=$fatal, reason=$reason]: $exception');
        if (stack != null) debugPrint(stack.toString());
      }
      log('error: ${_truncate('$exception', 160)}');
      if (!remoteReportingEnabled) return;

      final payload = buildPayload(
        exception: exception,
        stack: stack,
        reason: reason,
        fatal: fatal,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        appVersion: AppConfig.appVersion,
        userId: _userId,
        breadcrumbs: List<String>.unmodifiable(_breadcrumbs),
      );
      final signature = '${payload['message']}|${payload['reason']}';
      if (!shouldSend(signature)) return;
      unawaited(_send(payload));
    } catch (_) {
      // Reporting must never crash the app.
    }
  }

  /// Pure function: builds the size-limited payload (testable, no I/O).
  @visibleForTesting
  static Map<String, Object?> buildPayload({
    required dynamic exception,
    StackTrace? stack,
    dynamic reason,
    required bool fatal,
    required String platform,
    required String appVersion,
    String? userId,
    List<String> breadcrumbs = const [],
  }) {
    final recent = breadcrumbs.length > breadcrumbsPerReport
        ? breadcrumbs.sublist(breadcrumbs.length - breadcrumbsPerReport)
        : breadcrumbs;
    return <String, Object?>{
      'message': _truncate('$exception', maxMessageLength),
      'stack': _truncate(stack?.toString() ?? '', maxStackLength),
      'reason': _truncate('${reason ?? ''}', maxReasonLength),
      'fatal': fatal,
      'platform': platform,
      'appVersion': appVersion,
      'uid': userId,
      'breadcrumbs': _truncate(recent.join('\n'), maxBreadcrumbLength),
    };
  }

  /// Rate limit + de-duplication. Returns true if this error may be uploaded.
  @visibleForTesting
  static bool shouldSend(String signature) {
    if (_sentCount >= maxReportsPerSession) return false;
    if (!_sentSignatures.add(signature)) return false;
    _sentCount++;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    _sentSignatures.clear();
    _sentCount = 0;
    _breadcrumbs.clear();
    _userId = null;
  }

  @visibleForTesting
  static List<String> get breadcrumbsForTesting =>
      List<String>.unmodifiable(_breadcrumbs);

  static Future<void> _send(Map<String, Object?> payload) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('client_errors')
          .add({...payload, 'createdAt': FieldValue.serverTimestamp()})
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Offline or rules rejected: drop silently, never loop.
    }
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  /// Set user ID for crash reports (opaque Firebase uid, no email).
  static void setUserIdentifier(String userId) {
    _userId = userId;
    log('User session set');
  }

  /// Clear user ID on logout.
  static void clearUserIdentifier() {
    _userId = null;
    log('User session cleared');
  }
}
