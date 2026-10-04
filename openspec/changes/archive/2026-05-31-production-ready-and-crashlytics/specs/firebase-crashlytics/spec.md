## ADDED Requirements

### Requirement: Firebase Crashlytics SDK integration
The Flutter app SHALL declare `firebase_core` and `firebase_crashlytics` as runtime dependencies in `pubspec.yaml`, and the Android project SHALL include the `google-services` Gradle plugin applied to `android/app/build.gradle.kts`, with the `google-services.json` configuration file placed at `android/app/google-services.json`.

#### Scenario: App builds successfully with Firebase dependencies
- **WHEN** the developer runs `flutter pub get` followed by `flutter build apk --debug`
- **THEN** the build succeeds without unresolved dependency or Gradle errors

#### Scenario: google-services.json is present for Android
- **WHEN** the Android build system processes `android/app/`
- **THEN** `google-services.json` is found at `android/app/google-services.json` and the `google-services` plugin processes it without error

### Requirement: Firebase initialisation at app startup
The app SHALL call `await Firebase.initializeApp()` during the Flutter engine initialisation phase (inside `runZonedGuarded`, before `runApp`), so that Crashlytics is ready before any user-visible screen renders.

#### Scenario: Firebase initialises before first screen
- **WHEN** the app launches in release or profile mode
- **THEN** `Firebase.initializeApp()` completes successfully before `runApp` is called, and no "Firebase not initialised" exception is thrown

#### Scenario: Initialisation failure is logged and rethrown
- **WHEN** `Firebase.initializeApp()` throws (e.g., missing `google-services.json`)
- **THEN** the error is written to `AppLogger` and propagated so the developer sees a clear failure message

### Requirement: Unhandled Flutter errors forwarded to Crashlytics
`FlutterError.onError` SHALL chain a call to `FirebaseCrashlytics.instance.recordFlutterFatalError` after the existing `AppLogger.error` call, so that widget build/layout errors are captured in the Crashlytics dashboard in release builds.

#### Scenario: Widget error captured in release mode
- **WHEN** a widget throws an unhandled exception during build and the app is running in release mode
- **THEN** the error is forwarded to `FirebaseCrashlytics.instance.recordFlutterFatalError` and appears in the Firebase console

#### Scenario: Widget error still logged locally in debug mode
- **WHEN** a widget throws an unhandled exception in debug mode
- **THEN** `AppLogger.error` captures the error and the Crashlytics call is a no-op (collection disabled)

### Requirement: Unhandled async errors forwarded to Crashlytics
The `runZonedGuarded` catch block SHALL call `FirebaseCrashlytics.instance.recordError(error, stack, fatal: true)` after logging, so that uncaught async errors (e.g., unhandled `Future` rejections) are captured in release builds.

#### Scenario: Uncaught async error captured in release mode
- **WHEN** an async callback throws an unhandled exception at runtime in release mode
- **THEN** the error is recorded via `FirebaseCrashlytics.instance.recordError` with `fatal: true`

### Requirement: Crashlytics collection disabled outside release mode
`FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode)` SHALL be called immediately after Firebase initialisation, ensuring that debug and test runs do not send reports to the Crashlytics dashboard.

#### Scenario: Collection disabled in debug mode
- **WHEN** the app is launched with `flutter run` (debug mode)
- **THEN** `setCrashlyticsCollectionEnabled` is set to `false` and no crash reports are transmitted

#### Scenario: Collection enabled in release mode
- **WHEN** the app is built with `flutter build appbundle --release`
- **THEN** `setCrashlyticsCollectionEnabled` is set to `true` and crash reports are transmitted on error
