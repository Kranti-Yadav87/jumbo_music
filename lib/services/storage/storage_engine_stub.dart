class PlatformStorage {
  static final Map<String, String> _mem = {};

  static Future<String?> getItem(String key) async {
    return _mem[key];
  }

  static Future<void> setItem(String key, String value) async {
    _mem[key] = value;
  }

  static Future<void> removeItem(String key) async {
    _mem.remove(key);
  }
}
