import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Emits a PNG of the current screen when the run is started with
/// `--dart-define=SAVE_SCREENSHOTS=true`, for a human to review UI changes.
/// `flutter test` uninstalls the app when it finishes, so the image is
/// printed to the test output as base64 lines (`SCREENSHOT <name> <chunk>`)
/// — rebuild it with
/// `grep '^SCREENSHOT <name> ' log | cut -d' ' -f3 | tr -d '\n' | base64 -d`.
/// A no-op otherwise, so CI runs are unaffected.
///
/// Renders the root layer in-process rather than using the integration_test
/// binding's platform screenshot, which needs the Flutter surface converted
/// to an image (per test) and breaks taps made afterwards.
Future<void> saveScreenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SAVE_SCREENSHOTS')) return;
  await tester.pumpAndSettle();
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    // The root layer already carries the device-pixel-ratio transform, so
    // capture its full physical extent 1:1.
    final image = await layer.toImage(
      Offset.zero & (view.size * view.flutterView.devicePixelRatio),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final encoded = base64Encode(png!.buffer.asUint8List());
    for (var i = 0; i < encoded.length; i += 800) {
      // ignore: avoid_print
      print('SCREENSHOT $name ${encoded.substring(i, min(i + 800, encoded.length))}');
    }
  });
}
