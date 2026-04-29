import 'dart:developer' as developer;

/// Lightweight structured logger wrapping `dart:developer`.
///
/// Usage:
/// ```dart
/// AppLogger.info('User signed in', name: 'AuthBloc');
/// AppLogger.error('Network request failed', error: e, stackTrace: st);
/// ```
class AppLogger {
  AppLogger._();

  static const String _defaultName = 'ArunikaApp';

  /// Log a debug-level message (only meaningful in debug/profile builds).
  static void debug(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 500, // dart:developer Level.FINE
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an informational message.
  static void info(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 800, // dart:developer Level.INFO
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning.
  static void warning(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 900, // dart:developer Level.WARNING
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error with optional exception and stack trace.
  static void error(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000, // dart:developer Level.SEVERE
      error: error,
      stackTrace: stackTrace,
    );
  }
}
