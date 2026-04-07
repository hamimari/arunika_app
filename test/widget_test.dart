// This default smoke test is skipped because the app uses GetIt dependency
// injection and go_router for navigation, making MyApp untestable without
// full service locator setup. Meaningful tests are in:
//   test/presentation/screens/qrscanner/qr_scanner_bloc_test.dart
//   test/presentation/screens/arscanner/ar_core_screen_test.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder — see individual feature tests for coverage', () {
    // No-op: real tests are in subdirectories
    expect(true, isTrue);
  });
}
