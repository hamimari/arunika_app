class AppConfig {
  /// API base URL. Defaults to production so a release build can't ship
  /// pointing anywhere else; for local development override it with:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.haloarunika.com',
  );

  // Backward-compatible alias used by DioClient and other legacy call-sites.
  static const String baseUrl = apiBaseUrl;
}
