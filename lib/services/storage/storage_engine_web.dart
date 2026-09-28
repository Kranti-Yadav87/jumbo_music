import 'dart:js_interop';

@JS('jumboStorageGet')
external JSString? _jsStorageGet(JSString key);

@JS('jumboStorageSet')
external void _jsStorageSet(JSString key, JSString value);

@JS('jumboStorageRemove')
external void _jsStorageRemove(JSString key);

class PlatformStorage {
  static final Map<String, String> _memCache = {};

  static Future<String?> getItem(String key) async {
    if (_memCache.containsKey(key)) {
      return _memCache[key];
    }
    try {
      final res = _jsStorageGet(key.toJS);
      final val = res?.toDart;
      if (val != null) {
        _memCache[key] = val;
      }
      return val;
    } catch (_) {
      return _memCache[key];
    }
  }

  static Future<void> setItem(String key, String value) async {
    _memCache[key] = value;
    try {
      _jsStorageSet(key.toJS, value.toJS);
    } catch (_) {}
  }

  static Future<void> removeItem(String key) async {
    _memCache.remove(key);
    try {
      _jsStorageRemove(key.toJS);
    } catch (_) {}
  }
}
