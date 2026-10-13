import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';

/// Manages Android 13+ (POST_NOTIFICATIONS) runtime permission requests
/// with user rationale before first playback and open-settings fallback for permanently denied states.
class NotificationPermissionService {
  static final NotificationPermissionService instance =
      NotificationPermissionService._internal();

  NotificationPermissionService._internal();

  bool _hasPrompted = false;
  bool get hasPrompted => _hasPrompted;

  @visibleForTesting
  void resetForTesting() {
    _hasPrompted = false;
  }

  /// Optional test mocks
  static TargetPlatform? mockTargetPlatform;
  static Future<PermissionStatus> Function()? mockStatusCheck;
  static Future<PermissionStatus> Function()? mockRequest;
  static Future<bool> Function()? mockOpenSettings;

  Future<PermissionStatus> getStatus() async {
    if (mockStatusCheck != null) {
      return await mockStatusCheck!();
    }
    return await Permission.notification.status;
  }

  /// Checks notification permission before playback and presents a rationale dialog if not yet granted.
  Future<void> requestNotificationPermissionIfNeeded({
    BuildContext? context,
  }) async {
    final platform = mockTargetPlatform ?? defaultTargetPlatform;
    if (kIsWeb || platform != TargetPlatform.android) {
      return;
    }

    if (_hasPrompted) {
      return;
    }
    _hasPrompted = true;

    final currentStatus = await getStatus();
    if (currentStatus.isGranted) {
      return;
    }

    final ctx = context ?? JumboMusicApp.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      if (currentStatus.isPermanentlyDenied) {
        _showPermanentlyDeniedDialog(ctx);
        return;
      }

      final shouldRequest = await _showRationaleDialog(ctx);
      if (!shouldRequest) {
        return;
      }
    }

    final newStatus = mockRequest != null
        ? await mockRequest!()
        : await Permission.notification.request();

    if (newStatus.isPermanentlyDenied) {
      final postCtx = context ?? JumboMusicApp.navigatorKey.currentContext;
      if (postCtx != null && postCtx.mounted) {
        _showPermanentlyDeniedDialog(postCtx);
      }
    }
  }

  Future<bool> _showRationaleDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF6366F1),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Media Controls',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Enable notifications so Jumbo Music can show song controls (Play, Pause, Next, Prev, and live Seek) on your lock screen, notification shade, and Bluetooth neckband.',
          style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Not Now',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.settings_suggest_rounded,
              color: Color(0xFFA855F7),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Enable Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Notifications are currently blocked. To enjoy lock screen controls and Bluetooth neckband controls, please enable notifications in App Settings.',
          style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mockOpenSettings != null) {
                mockOpenSettings!();
              } else {
                openAppSettings();
              }
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
