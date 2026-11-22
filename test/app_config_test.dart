import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Has valid app metadata', () {
      expect(AppConfig.appName, equals('Jumbo Music'));
      expect(AppConfig.appVersion, equals('2.0.0'));
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
