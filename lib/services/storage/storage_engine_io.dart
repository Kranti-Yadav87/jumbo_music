import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PlatformStorage {
  static final Map<String, String> _memCache = {};
  static Directory? _dir;

  static Future<void> _ensureDir() async {
    if (_dir != null) return;
    try {
      final base = await getApplicationDocumentsDirectory();
      _dir = Directory('${base.path}${Platform.pathSeparator}.jumbo_vault');
      if (!await _dir!.exists()) {
        await _dir!.create(recursive: true);
      }
    } catch (_) {
      try {
        _dir = Directory('.jumbo_vault');
        if (!await _dir!.exists()) {
          await _dir!.create(recursive: true);
        }
      } catch (_) {}
    }
  }

  static Future<String?> getItem(String key) async {
    if (_memCache.containsKey(key)) {
      return _memCache[key];
    }
    try {
      await _ensureDir();
      final file = File('${_dir?.path ?? '.'}/$key.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        _memCache[key] = content;
        return content;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> setItem(String key, String value) async {
    _memCache[key] = value;
    try {
      await _ensureDir();
      final file = File('${_dir?.path ?? '.'}/$key.json');
      await file.writeAsString(value);
    } catch (_) {}
  }

  static Future<void> removeItem(String key) async {
    _memCache.remove(key);
    try {
      await _ensureDir();
      final file = File('${_dir?.path ?? '.'}/$key.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
