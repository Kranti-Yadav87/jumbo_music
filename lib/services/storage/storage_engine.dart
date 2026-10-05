import 'package:flutter/foundation.dart';
import 'storage_engine_stub.dart'
    if (dart.library.js_interop) 'storage_engine_web.dart'
    if (dart.library.io) 'storage_engine_io.dart'
    as platform;

class StorageEngine {
  @visibleForTesting
  static bool inMemoryOnly = false;

  static final Map<String, String> _memStorage = {};

  static Future<String?> getItem(String key) {
    if (inMemoryOnly) return Future.value(_memStorage[key]);
    return platform.PlatformStorage.getItem(key);
  }

  static Future<void> setItem(String key, String value) {
    if (inMemoryOnly) {
      _memStorage[key] = value;
      return Future.value();
    }
    return platform.PlatformStorage.setItem(key, value);
  }

  static Future<void> removeItem(String key) {
    if (inMemoryOnly) {
      _memStorage.remove(key);
      return Future.value();
    }
    return platform.PlatformStorage.removeItem(key);
  }

  @visibleForTesting
  static void clearMemoryStorage() {
    _memStorage.clear();
  }
}
