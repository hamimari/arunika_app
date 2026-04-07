class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://nonciteable-lovella-cacophonously.ngrok-free.dev',
  );
}
