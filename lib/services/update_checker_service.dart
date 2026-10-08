import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UpdateCheckerService {
  UpdateCheckerService._();
  static final UpdateCheckerService instance = UpdateCheckerService._();

  bool _checked = false;

  Future<void> checkForUpdates(BuildContext context) async {
    if (_checked || kIsWeb || defaultTargetPlatform != TargetPlatform.android)
      return;
    _checked = true;

    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/Kranti-Yadav87/jumbo_music/releases/latest',
            ),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tagName = data['tag_name'] as String? ?? '';
        final htmlUrl = data['html_url'] as String? ?? AppConfig.apkDownloadUrl;
        final releaseName = data['name'] as String? ?? tagName;

        if (tagName.isNotEmpty &&
            !tagName.contains(AppConfig.appVersion) &&
            context.mounted) {
          _showUpdateDialog(context, releaseName, htmlUrl);
        }
      }
    } catch (_) {
      // Silent on network timeout
    }
  }

  void _showUpdateDialog(
    BuildContext context,
    String releaseName,
    String downloadUrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.system_update_rounded,
              color: Color(0xFF6366F1),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'New Update Available',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          '$releaseName is now available. Update now to enjoy the latest performance improvements, new music streams, and features.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.download_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              'Get Update',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Clipboard.setData(
                ClipboardData(text: AppConfig.apkDownloadUrl),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '📥 Download link copied to clipboard! Open in browser to install.',
                    ),
                    backgroundColor: Color(0xFF6366F1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
