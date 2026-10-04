## Why

The app and backend have accumulated implementation gaps that must be closed before a production release: several BLoCs/Cubits and backend service/handler layers lack unit tests, and there is no crash-reporting pipeline to diagnose production failures. Firebase Crashlytics provides real-time crash visibility with zero runtime overhead when no crash occurs, and closing the test gaps ensures regressions are caught before they reach users.

## What Changes

- **Firebase Crashlytics integration**: Add `firebase_core` and `firebase_crashlytics` to the Flutter app; wire `google-services.json` for Android; capture all unhandled Flutter errors and uncaught async errors; expose a helper to manually log non-fatal errors.
- **Flutter unit-test gaps closed**: Add missing BLoC/Cubit test files for `HomeDongengSectionBloc`, `HomeBannerCubit`, and `PremiumPackCubit`; each file covers at minimum one happy-path and one error scenario per event/method.
- **Backend unit-test gaps closed**: Add missing service-layer tests for `AnimalService`, `PaymentService`, and `PremiumPackService`; expand handler-level tests to cover `AnimalHandler`, `AuthHandler`, `BannerHandler`, `CategoryHandler`, `DongengHandler`, `PaymentHandler`, and `UserHandler` (happy path + error path per endpoint).
- **Backend code tidy-up**: Remove dead/unreferenced code, rename the misnamed `catry_service.go` file, ensure all handlers validate input before calling services, and confirm no hard-coded secrets remain.
- **Flutter code tidy-up**: Complete the `TODO: integrate audioplayer` in `GuessAnimalVoiceScreen`; remove any unused imports flagged by the analyser; confirm `flutter analyze` passes with zero warnings.

## Capabilities

### New Capabilities
- `firebase-crashlytics`: Crash reporting pipeline — Firebase SDK wiring, error capture at the Flutter entry point, non-fatal logging helper, and Android `google-services.json` configuration.

### Modified Capabilities
- `flutter-unit-tests`: Adds mandatory coverage for the three previously untested BLoCs/Cubits (`HomeDongengSectionBloc`, `HomeBannerCubit`, `PremiumPackCubit`).
- `backend-unit-tests`: Adds mandatory coverage for the three untested service classes and expands handler-level test requirements to all handlers.

## Impact

- **Flutter app**: `pubspec.yaml` gains `firebase_core` and `firebase_crashlytics`; `android/app/google-services.json` added; `main.dart` updated to initialise Firebase and set error handlers; `GuessAnimalVoiceScreen` gains audio-player integration.
- **Backend**: `services/catry_service.go` renamed; 3 new `*_test.go` service files; `handlers/handler_test.go` extended; no API contract changes.
- **CI / build**: Android build requires the `google-services` Gradle plugin; no iOS changes unless Apple distribution is in scope.
