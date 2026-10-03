import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/song.dart';

/// Real system share sheet (WhatsApp, Instagram, etc.) with a clipboard fallback.
class ShareService {
  ShareService._();

  static String get appUrl => kIsWeb ? Uri.base.origin : AppConfig.webAppUrl;

  static String songMessage(Song song) =>
      '🎵 "${song.title}" by ${song.artist}\nListen on Jumbo Music: $appUrl';

  static String appMessage() =>
      '🎧 Jumbo Music - free music streaming for every language!\n$appUrl';

  static Future<void> shareSong(BuildContext context, Song song) =>
      _share(context, songMessage(song), '${song.title} • Jumbo Music');

  static Future<void> shareApp(BuildContext context) =>
      _share(context, appMessage(), 'Jumbo Music');

  static Future<void> _share(
    BuildContext context,
    String text,
    String subject,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    Rect? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      );
      if (result.status == ShareResultStatus.unavailable) {
        await _copyFallback(messenger, text);
      }
    } catch (_) {
      await _copyFallback(messenger, text);
    }
  }

  static Future<void> _copyFallback(
    ScaffoldMessengerState? messenger,
    String text,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Sharing is not available here - link copied instead.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
