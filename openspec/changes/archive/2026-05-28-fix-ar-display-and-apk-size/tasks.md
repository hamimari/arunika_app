## 1. AR Auto-Placement

- [x] 1.1 Remove `onPlaneOrPointTap` handler and `handleTaps: true` from `ArCoreSurfacePlaceScreen` initialization in `ar_core_screen.dart`
- [x] 1.2 Add a `bool _placed = false` guard flag to `ArCoreSurfacePlaceScreen` state
- [x] 1.3 Subscribe to `arSessionManager.onPlaneDetected` callback; on first upward-facing horizontal plane detection, call the placement logic and set `_placed = true`
- [x] 1.4 Extract model placement logic into a `_placeModel(ARPlane plane)` method that creates an `ARPlaneAnchor` from the plane and adds the initial `ARNode`
- [x] 1.5 Add a pre-placement hint overlay widget (e.g., centered text "Point at a flat surface") that is visible when `!_placed` and hidden after placement
- [x] 1.6 Verify that subsequent plane detection events after first placement do not trigger additional node additions

## 2. Entrance Zoom-In Animation

- [x] 2.1 Add `AnimationController _entranceController` and `Animation<double> _entranceAnimation` as state fields; initialize with 600ms duration and `Curves.elasticOut`
- [x] 2.2 In `_placeModel`, set initial node scale to 0 and start `_entranceController.forward()`
- [x] 2.3 Add an `_entranceAnimation` listener that calls `_throttledApply()` with the animated scale value on each frame
- [x] 2.4 Set a `_animating` flag to `true` during the entrance animation and `false` in `addStatusListener` when `AnimationStatus.completed`
- [x] 2.5 Guard gesture update handlers (`_onScaleUpdate`) to return early when `_animating` is `true`
- [x] 2.6 Dispose `_entranceController` in the widget's `dispose()` method

## 3. Gesture Interaction Improvements

- [x] 3.1 Refactor `_onScaleUpdate` to use a `_pendingScale` and `_pendingRotationY` accumulator pattern; only call `_throttledApply()` when scale delta > 1% or rotation delta > 0.5 degrees
- [x] 3.2 Replace the existing 30ms `Future.delayed` debounce with a `Timer` that resets on each gesture event, so rapid micro-updates are coalesced
- [x] 3.3 Clamp `_currentScale` between `0.2` and `2.5` in the accumulator before applying
- [x] 3.4 Add `onScaleStart` handler to capture initial scale and rotation values, preventing jumps when a gesture starts

## 4. Production Build Configuration

- [x] 4.1 In `android/app/build.gradle.kts`, add `isMinifyEnabled = true` and `isShrinkResources = true` to the `release` buildType block
- [x] 4.2 Add `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")` to the `release` buildType
- [x] 4.3 Add ABI splits block: enable splits for `arm64-v8a`, `armeabi-v7a`, `x86_64`; set `universalApk = false`
- [x] 4.4 Create `android/app/proguard-rules.pro` with keep rules for: `com.google.ar.**`, `io.github.sceneview.**`, `com.gordonwong.**`, `okhttp3.**`, `retrofit2.**`, and Flutter's `io.flutter.**`
- [x] 4.5 Add a `release` signing config in `build.gradle.kts` that reads `storeFile`, `storePassword`, `keyAlias`, `keyPassword` from a `key.properties` file (loaded via `Properties`)
- [x] 4.6 Update the `release` buildType to reference the new `release` signing config instead of `debug`
- [x] 4.7 Create `android/key.properties.example` documenting the required keys (do NOT create `key.properties` itself; add it to `.gitignore`)
- [x] 4.8 Add `android/key.properties` to `.gitignore` if not already present

## 5. Unit and Widget Tests

- [x] 5.1 Write unit tests for `QRScannerBloc`: test `FetchModelById` emits `ModelLoading` then `ModelLoaded` on success, and `ModelError` on API failure
- [x] 5.2 Write unit tests for `QRScannerBloc`: test that a second scan while `_scanned = true` does not dispatch a second event
- [x] 5.3 Write a widget test for `ArCoreSurfacePlaceScreen`: verify the pre-placement hint overlay is visible on initial render
- [x] 5.4 Write a widget test for `ArCoreSurfacePlaceScreen`: mock `arSessionManager.onPlaneDetected` and verify that triggering it once sets `_placed = true` and hides the hint overlay
- [x] 5.5 Write a widget test for `ArCoreSurfacePlaceScreen`: verify that triggering `onPlaneDetected` a second time does not call `arObjectManager.addNode` again (guard flag test)
- [x] 5.6 Run `flutter test` and ensure all tests pass with no errors

## 6. Verification

- [x] 6.1 Run `flutter build appbundle --release` and record the output AAB size; confirm it is significantly smaller than the previous 50 MB APK
- [x] 6.2 Run `flutter build apk --split-per-abi --release` and confirm per-ABI APKs are generated
- [ ] 6.3 Install the app on a physical ARCore-supported device; verify the model appears automatically after QR scan without any tap
- [ ] 6.4 On device, verify the zoom-in entrance animation plays smoothly on first model placement
- [ ] 6.5 On device, verify pinch-to-zoom and drag-to-rotate gestures work without visible jank
- [x] 6.6 Run `flutter analyze` and confirm no new warnings or errors
