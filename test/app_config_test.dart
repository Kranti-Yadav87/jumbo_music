import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Has valid default endpoint and anon key', () {
      expect(AppConfig.supabaseEndpoint, isNotEmpty);
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
      expect(AppConfig.supabaseEndpoint.startsWith('https://'), isTrue);
    });

    test('Generates complete API headers map', () {
      final headers = AppConfig.apiHeaders;
      expect(headers['apikey'], equals(AppConfig.supabaseAnonKey));
      expect(
        headers['Authorization'],
        equals('Bearer ${AppConfig.supabaseAnonKey}'),
      );
      expect(headers['Content-Type'], equals('application/json'));
    });
  });
}
