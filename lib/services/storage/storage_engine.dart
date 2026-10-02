import 'storage_engine_stub.dart'
    if (dart.library.js_interop) 'storage_engine_web.dart'
    if (dart.library.io) 'storage_engine_io.dart'
    as platform;

class StorageEngine {
  static Future<String?> getItem(String key) =>
      platform.PlatformStorage.getItem(key);
  static Future<void> setItem(String key, String value) =>
      platform.PlatformStorage.setItem(key, value);
  static Future<void> removeItem(String key) =>
      platform.PlatformStorage.removeItem(key);
}
