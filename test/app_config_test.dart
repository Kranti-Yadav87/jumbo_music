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

    test('USE_UNOFFICIAL_CATALOG defaults to true', () {
      expect(AppConfig.useUnofficialCatalog, isTrue);
      expect(AppConfig.isUnofficialCatalogEnabled, isTrue);
    });

    test('isUnofficialCatalogEnabled respects test overrides', () {
      AppConfig.mockUseUnofficialCatalog = false;
      expect(AppConfig.isUnofficialCatalogEnabled, isFalse);

      AppConfig.mockUseUnofficialCatalog = true;
      expect(AppConfig.isUnofficialCatalogEnabled, isTrue);

      AppConfig.mockUseUnofficialCatalog = null;
      expect(
        AppConfig.isUnofficialCatalogEnabled,
        AppConfig.useUnofficialCatalog,
      );
    });

    test('activeJamendoClientId respects test overrides', () {
      AppConfig.mockJamendoClientId = 'test_key_123';
      expect(AppConfig.activeJamendoClientId, equals('test_key_123'));

      AppConfig.mockJamendoClientId = null;
      expect(AppConfig.activeJamendoClientId, AppConfig.jamendoClientId);
    });
  });
}
