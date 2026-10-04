## Context

The app is a Flutter-based children's educational app targeting Android (minSdk 28, ARCore required). The current AR flow uses `ar_flutter_plugin_2` which wraps ARCore's Sceneform SDK. The user must scan a QR code which resolves a `.glb` model URL via a REST API, then navigate to an AR screen where they must **tap a detected plane** to place the 3D model. Gestures (pinch/rotate) work by destroying and re-adding the ARNode on every update — causing visible jank.

The production release APK is ~50 MB. The build configuration has no ABI splitting, no R8 minification, no resource shrinking, and uses the debug signing config for release builds.

**Constraints:**
- Must stay on Flutter + Dart
- ARCore is required (Android only; iOS is out of scope)
- minSdk 28 is fixed by ARCore
- `.glb` models are loaded from a remote URL

---

## Goals / Non-Goals

**Goals:**
- Automatically display the AR model immediately when a horizontal plane is detected (no tap required)
- Play a smooth zoom-in entrance animation (scale 0 → target) when the model first appears
- Support free pinch-to-zoom and drag-to-rotate with minimal jank
- Reduce production APK/AAB size significantly (target: under 20 MB per ABI)
- Ship production-ready release build config (R8, resource shrinking, real signing)
- Add unit/widget tests for BLoC flow and AR screen placement trigger

**Non-Goals:**
- iOS AR support
- Multi-model placement (one model per AR session)
- Offline model caching (deferred to a future change)
- Full end-to-end integration tests on device

---

## Decisions

### Decision 1: Keep `ar_flutter_plugin_2` vs. Migrate

**Options considered:**
- **A) Stay with `ar_flutter_plugin_2`**: It wraps ARCore Sceneform. Auto-placement is achievable by calling `addNode` inside `onPlaneDetected` instead of `onPlaneOrPointTap`. Live rotation/scale updates without node recreation are **not** supported — the plugin has no `updateNode` API.
- **B) Migrate to `flutter_arcore` or native ARCore via Method Channel**: Full control but very high effort; no pub.dev package with active maintenance covers all requirements out of the box.
- **C) Use `model_viewer_plus`**: Renders `.glb` via a WebView-based model viewer. No real ARCore plane detection, but supports a lightweight "AR" mode on supported browsers. Lacks plane detection; not suitable.
- **D) Stay with `ar_flutter_plugin_2` + optimize gesture updates**: Auto-placement is implementable. For gestures, the node-recreate pattern can be made visually smooth by accumulating deltas and only applying when scale/rotation change exceeds a threshold (dead-zone debounce). This avoids a library migration.

**Decision: Option D** — stay with `ar_flutter_plugin_2` and improve gesture handling. The auto-placement requirement is directly achievable. Gesture smoothness can be improved with debounce dead-zones and a minimum delta threshold. A library migration would require significant testing and carries higher risk for a children's app.

### Decision 2: Auto-Placement Trigger

**Options considered:**
- **A) Place on first plane detected** (`onPlaneDetected` callback): Places the model as soon as any horizontal plane appears, with no user action. Feels magical for children.
- **B) Place on first tap after auto-detected**: Hybrid — still requires tap, does not meet requirement.
- **C) Place after a 2-second delay**: Timer-based; fragile if plane detection is slow.

**Decision: Option A** — place on the first detected horizontal plane. The session manager's `onPlaneDetected` fires when ARCore first tracks a horizontal surface. Place the model centered on that plane's anchor. A `_placed` guard flag prevents double-placement.

### Decision 3: Entrance Zoom-In Animation

**Options considered:**
- **A) Animate scale in the AR node via repeated `removeNode`/`addNode` at 60fps**: Jank-inducing, same problem as gestures.
- **B) ARNode scale property + `AnimationController` stepping**: Drive a `Tween<double>(begin: 0, end: 1)` and update the node's scale from Flutter's `AnimationController`. Apply only when delta is meaningful (>1% change).
- **C) Use `ar_flutter_plugin_2`'s built-in animation**: Not supported by the plugin.

**Decision: Option B** — use Flutter `AnimationController` with a `CurvedAnimation(curve: Curves.elasticOut)` for a bouncy, child-friendly scale-up. Tween drives `_currentScale` from 0 to the base scale value over 600ms. Node updates use the same threshold-guarded `_throttledApply` as gestures.

### Decision 4: APK Size Reduction Strategy

**Options considered:**
- **A) ABI splits only**: Reduces APK per-device but Google Play stores require a separate upload per ABI.
- **B) Android App Bundle (AAB)**: Google Play delivers the correct ABI/density slice automatically. This is the recommended production approach. Reduces effective install size.
- **C) AAB + R8 full mode + resource shrinking**: Maximum size reduction. R8 removes unused code; `shrinkResources` removes unused drawables/strings.

**Decision: Option C** — enable AAB as the primary release artifact, plus R8 (`isMinifyEnabled = true`) and `shrinkResources = true`. Add ABI splits as well so direct APK distribution also produces smaller per-ABI files. Add a `proguard-rules.pro` with keep rules for AR, QR scanner, and Dio reflection targets.

### Decision 5: Release Signing

The current `release` buildType uses `signingConfigs.getByName("debug")`. For production this must use a real keystore. The design will add a `release` signing config that reads from environment variables or a `key.properties` file (not committed to VCS), which is the standard Flutter pattern.

---

## Risks / Trade-offs

- **[Risk] Auto-placement on first plane may misplace the model on an unintended surface** → Mitigation: Limit `onPlaneDetected` to `PlaneType.horizontal_upward` only; show a brief overlay "Point at a flat surface" hint until placed.
- **[Risk] `AnimationController` + node recreation still causes some jank on low-end devices** → Mitigation: Increase debounce threshold to 50ms minimum between node updates; cap max gesture velocity.
- **[Risk] R8 may strip ARCore/Sceneform classes** → Mitigation: Add comprehensive keep rules in `proguard-rules.pro` for `com.google.ar.**`, `io.github.sceneview.**`, and `com.gordonwong.flutter.ar.**`.
- **[Risk] `ar_flutter_plugin_2` is a low-activity pub.dev package** → Mitigation: Pin to a known-good version; if the package becomes unmaintained before next release, escalate migration to `flutter_arcore_ground_plane` or a native channel.
- **[Risk] Signing config with key.properties may cause CI failures** → Mitigation: Document required env vars; provide a CI-safe fallback that fails the build with a clear error rather than silently using debug signing.

---

## Migration Plan

1. Update `pubspec.yaml` if any package version changes are needed; run `flutter pub get`.
2. Refactor `ar_core_screen.dart` — remove tap handler, add auto-placement, add `AnimationController`, improve gesture throttle.
3. Update `android/app/build.gradle.kts` — add ABI splits, R8, resource shrinking.
4. Create `android/app/proguard-rules.pro` with required keep rules.
5. Add `android/key.properties` reference and signing config (document setup steps; do not commit key file).
6. Write tests: BLoC unit tests, AR screen widget tests.
7. Run `flutter build appbundle --release` and verify AAB size.
8. Run `flutter test` and verify all tests pass.

**Rollback**: The AR library version is pinned; reverting `ar_core_screen.dart` restores previous behavior. Build config changes are additive and can be reverted independently.

---

## Open Questions

- None critical. The signing keystore setup requires a decision from the project owner (where to store the keystore file in CI/CD), but this is an operational concern and does not block implementation.
