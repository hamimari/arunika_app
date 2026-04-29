import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    test('debug does not throw', () {
      expect(() => AppLogger.debug('debug message'), returnsNormally);
    });

    test('info does not throw', () {
      expect(() => AppLogger.info('info message'), returnsNormally);
    });

    test('warning does not throw', () {
      expect(() => AppLogger.warning('warning message'), returnsNormally);
    });

    test('error does not throw', () {
      expect(() => AppLogger.error('error message'), returnsNormally);
    });

    test('error with exception and stackTrace does not throw', () {
      final error = Exception('test error');
      final stackTrace = StackTrace.current;
      expect(
        () => AppLogger.error(
          'error with context',
          error: error,
          stackTrace: stackTrace,
        ),
        returnsNormally,
      );
    });

    test('all levels accept custom name', () {
      expect(
        () => AppLogger.info('message', name: 'CustomComponent'),
        returnsNormally,
      );
    });
  });
}
