import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Has valid default endpoint and secure empty default anon key', () {
      expect(AppConfig.supabaseEndpoint, isNotEmpty);
      expect(AppConfig.supabaseEndpoint.startsWith('https://'), isTrue);
      // Verify no hardcoded secrets or JWTs exist in code
      expect(AppConfig.supabaseAnonKey, isEmpty);
      expect(AppConfig.activeSupabaseAnonKey, isEmpty);
    });

    test(
      'Generates clean API headers without leaking keys when unconfigured',
      () {
        final headers = AppConfig.apiHeaders;
        expect(headers['Content-Type'], equals('application/json'));
        expect(headers.containsKey('apikey'), isFalse);
        expect(headers.containsKey('Authorization'), isFalse);
      },
    );

    test('Attaches auth headers when mockSupabaseAnonKey is supplied', () {
      AppConfig.mockSupabaseAnonKey = 'test_secret_anon_token';
      expect(AppConfig.activeSupabaseAnonKey, equals('test_secret_anon_token'));

      final headers = AppConfig.apiHeaders;
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['apikey'], equals('test_secret_anon_token'));
      expect(headers['Authorization'], equals('Bearer test_secret_anon_token'));

      AppConfig.mockSupabaseAnonKey = null;
      expect(AppConfig.activeSupabaseAnonKey, isEmpty);
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
