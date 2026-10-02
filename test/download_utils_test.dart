import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/download_utils.dart';

void main() {
  test('formatBytes picks a sensible unit', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.00 GB');
  });
}
