## Why

The current AR experience requires a manual tap to place a 3D model after a QR scan, which breaks the flow for young children who expect instant feedback. Additionally, the production APK is approximately 50 MB — large enough to deter installs on budget devices common in the target market.

## What Changes

- **Remove tap-to-place requirement**: The AR model must appear automatically after the QR scan and AR session initializes, with no user interaction needed.
- **Add zoom-in entrance animation**: The AR model scales from zero to its target size on first display to provide a smooth, engaging reveal effect.
- **Improve gesture interaction**: Free pinch-to-zoom and drag-to-rotate must work smoothly. The current node-destroy-and-recreate approach causes jank; transform updates should be applied without re-adding the node where the library permits.
- **Evaluate and replace AR library if needed**: If `ar_flutter_plugin_2` cannot support auto-placement and live transform updates, migrate to a library that can (e.g., `arkit_plugin` on iOS / native ARCore integration, or `flutter_unity_widget` / `model_viewer_plus` as a fallback).
- **APK size reduction**: Enable ABI splits, R8 minification, resource shrinking, and move to an Android App Bundle (AAB) release workflow to cut APK size significantly.
- **Production-ready hardening**: Replace debug signing config with release signing, add ProGuard/R8 keep rules for AR and QR libraries, and ensure no debug artifacts ship.
- **Unit and widget test coverage**: Add tests for the QR→AR BLoC flow and AR screen widget behavior (auto-placement trigger, gesture state).

## Capabilities

### New Capabilities

- `ar-display`: Automatic AR model display after QR scan with zoom-in entrance animation and free rotate/zoom gesture support.
- `apk-size-optimization`: Android build configuration changes (ABI splits, R8 minification, resource shrinking, AAB) to reduce release APK/bundle size.

### Modified Capabilities

<!-- No existing specs to modify — openspec/specs/ is currently empty -->

## Impact

- **`lib/presentation/screens/arscanner/ar_core_screen.dart`**: Major refactor — remove tap-to-place handler, add auto-placement on session ready, add entrance animation, improve gesture transform updates.
- **`lib/presentation/screens/qrscanner/qr_scanner.dart`**: Minor — verify navigation to AR screen passes all needed context for auto-start.
- **`pubspec.yaml`**: Potential AR library change; add/update dependencies.
- **`android/app/build.gradle.kts`**: Add ABI splits, R8 minification, resource shrinking, release signing config.
- **`android/app/proguard-rules.pro`** (new): Keep rules for AR, QR, and Dio libraries.
- **Tests**: New test files for BLoC and AR screen widget.
