import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:patrol/patrol.dart';

// Native-UI flows: the OS permission dialogs that plain integration_test cannot
// see. These boot the real app entrypoint (real Firebase init), so they belong
// in the nightly run, not a PR gate.

/// Clears whatever native system dialogs are up. Android 15+ emulators using
/// 16 KB pages also raise an "app isn't 16 KB compatible" dialog (the bundled
/// ARCore/Filament libraries are not aligned) that would otherwise sit on top
/// of the permission prompt under test, so it is dismissed first.
Future<bool> _grantIfAsked(PatrolIntegrationTester $) async {
  var granted = false;
  for (var i = 0; i < 4; i++) {
    try {
      await $.platform.mobile.tap(
        Selector(text: "Don't Show Again"),
        timeout: const Duration(seconds: 3),
      );
      continue;
    } catch (_) {
      // Compatibility dialog not showing.
    }
    if (await $.platform.mobile.isPermissionDialogVisible(
      timeout: const Duration(seconds: 8),
    )) {
      await $.platform.mobile.grantPermissionWhenInUse();
      granted = true;
    }
  }
  return granted;
}

void main() {
  patrolTest(
    'notification permission is requested at launch and can be granted',
    ($) async {
      app.main();
      await $.pump(const Duration(seconds: 5));

      await _grantIfAsked($);

      // The app carries on to its landing screen once the dialog is dealt with.
      await $(
        AppStrings.btnTryDemo,
      ).waitUntilVisible(timeout: const Duration(seconds: 30));
      expect(await $.platform.mobile.isPermissionDialogVisible(), isFalse);
    },
  );

  patrolTest(
    'camera permission is requested before QR scan and can be granted',
    ($) async {
      app.main();
      await $.pump(const Duration(seconds: 5));
      await _grantIfAsked($); // notification dialog, if this is a fresh install

      await $(
        AppStrings.btnTryDemo,
      ).waitUntilVisible(timeout: const Duration(seconds: 30));
      await $(AppStrings.btnTryDemo).tap();

      await $(
        find.byIcon(Iconsax.scan),
      ).waitUntilVisible(timeout: const Duration(seconds: 30));
      await $(find.byIcon(Iconsax.scan)).tap();

      expect(
        await $.platform.mobile.isPermissionDialogVisible(
          timeout: const Duration(seconds: 15),
        ),
        isTrue,
        reason: 'opening the QR scanner must ask for camera access',
      );
      await $.platform.mobile.grantPermissionWhenInUse();
      expect(await $.platform.mobile.isPermissionDialogVisible(), isFalse);
    },
  );
}
