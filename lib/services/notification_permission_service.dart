import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles runtime notification permissions for Android 13+ (POST_NOTIFICATIONS)
/// with an optional rationale dialog.
class NotificationPermissionService {
  NotificationPermissionService._();

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks if notification permission is already granted.
  static Future<bool> isPermissionGranted() async {
    if (!_isAndroid) return true;
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Requests notification permission with a short user-friendly rationale dialog
  /// if not already granted.
  static Future<void> requestNotificationPermissionIfNeeded(
    BuildContext context,
  ) async {
    if (!_isAndroid) return;

    try {
      final status = await Permission.notification.status;
      if (status.isGranted || status.isPermanentlyDenied) {
        return;
      }

      if (!context.mounted) return;

      // Show a concise rationale dialog before triggering the OS prompt
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 10),
                Text(
                  'Media Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Jumbo Music uses notifications to show playback controls (Play, Pause, Next, Favorite) on your lock screen and status bar.',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Not Now',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Allow Controls'),
              ),
            ],
          );
        },
      );

      if (shouldRequest == true) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }
}
