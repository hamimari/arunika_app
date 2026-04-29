import 'package:arunika_app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('apiBaseUrl is not empty', () {
      // In test environment no --dart-define is set, so the default value is used.
      expect(AppConfig.apiBaseUrl, isNotEmpty);
    });

    test('baseUrl equals apiBaseUrl (backward-compat alias)', () {
      expect(AppConfig.baseUrl, equals(AppConfig.apiBaseUrl));
    });

    test('apiBaseUrl starts with https in default value', () {
      // Default dev URL should be a valid HTTPS URL.
      expect(AppConfig.apiBaseUrl, startsWith('https://'));
    });
  });
}
