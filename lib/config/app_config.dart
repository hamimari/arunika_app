class AppConfig {
  /// API base URL. Override at build time with:
  ///   flutter run --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nonciteable-lovella-cacophonously.ngrok-free.dev',
  );

  // Backward-compatible alias used by DioClient and other legacy call-sites.
  static const String baseUrl = apiBaseUrl;
}
