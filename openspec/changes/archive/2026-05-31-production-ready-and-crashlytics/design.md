## Context

The app has a `runZonedGuarded` + `FlutterError.onError` setup in `main.dart` that already logs errors to `AppLogger`, but those logs are ephemeral (in-memory / console only). In production, crashes are invisible until a user reports them manually. Firebase Crashlytics provides a persistent, symbolicated crash report pipeline with zero instrumentation overhead on the happy path.

Separately, three BLoC/Cubit classes (`HomeDongengSectionBloc`, `HomeBannerCubit`, `PremiumPackCubit`) and three backend service classes (`AnimalService`, `PaymentService`, `PremiumPackService`) plus seven backend handlers have no automated tests. The backend also has a misnamed file (`catry_service.go`) and one in-code `TODO` in the Flutter layer.

## Goals / Non-Goals

**Goals:**
- Wire Firebase Crashlytics into the existing Flutter error-capture infrastructure so all unhandled errors are forwarded to the Crashlytics backend automatically.
- Close all identified Flutter BLoC/Cubit test gaps (3 files).
- Close all identified backend service and handler test gaps (3 service files, handler coverage extensions).
- Rename `catry_service.go` to `category_service.go` and resolve the `GuessAnimalVoiceScreen` audio TODO.
- Ensure `flutter analyze` and `go vet ./...` pass with zero warnings after all changes.

**Non-Goals:**
- iOS Firebase setup (Crashlytics requires `GoogleService-Info.plist`; deferred until iOS distribution is confirmed).
- Custom Crashlytics keys/attributes beyond the defaults.
- Performance monitoring or Remote Config (separate Firebase products).
- End-to-end / integration test coverage.

## Decisions

### 1. Crashlytics wraps the existing error hooks (not replaces them)

`FlutterError.onError` already calls `AppLogger.error`. We will chain a `FirebaseCrashlytics.instance.recordFlutterFatalError` call inside the same handler rather than replacing it. This preserves local debug logging while adding cloud reporting in release builds.

**Alternative considered:** Replace `AppLogger` calls with Crashlytics directly. Rejected because `AppLogger` is used in 20+ files and Crashlytics should be limited to crash boundaries, not general logging.

### 2. Crashlytics enabled only in release mode

We guard `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled` with `kReleaseMode` so that test runs and debug sessions do not pollute the Crashlytics dashboard.

**Alternative considered:** Always enable. Rejected because debug/test crashes would generate noise and exhaust free-tier quotas quickly.

### 3. `google-services.json` committed to the repo (Android only)

The `google-services.json` at `/Users/hamim.tohari/Downloads/google-service.json` contains no private server keys — it identifies the Firebase project for the client SDK, not a privileged secret. Committing it is the standard Flutter/Android practice and required by the `google-services` Gradle plugin.

**Alternative considered:** Load via CI environment variable. Adds friction for local development and is unnecessary for a client-side config file.

### 4. Backend file rename via `git mv`

`catry_service.go` → `category_service.go` to match the pattern of every other service file. All import references in the same package are implicit (Go packages, not file-level imports), so this is a cosmetic rename only.

### 5. `GuessAnimalVoiceScreen` audio integration uses `just_audio`

`just_audio` is already a declared dependency (`pubspec.yaml`). Re-using it avoids a new dependency and follows the same pattern as `DongengDetailScreen`.

## Risks / Trade-offs

- **`google-services` Gradle plugin version mismatch** → Check that `android/build.gradle` (project-level) declares the plugin at a version compatible with the current AGP. Most Flutter projects need `com.google.gms:google-services:4.4.x`.
- **Crashlytics in tests** → Unit tests that call into `main.dart` setup will fail if Firebase is not initialised. Mitigated by the `kReleaseMode` guard and by not calling `Firebase.initializeApp()` in test `main()`.
- **Backend rename breaks a running service** → `catry_service.go` is not referenced externally (Go package-level visibility). Zero runtime risk; change is compile-time only.
- **`AnimalService` lacks an interface/mock** → If the service uses concrete DB calls without a mockable interface, writing unit tests requires adding an interface first. May add minor scope creep.

## Migration Plan

1. Copy `google-service.json` → `android/app/google-services.json`.
2. Add `google-services` Gradle plugin to `android/build.gradle` (project-level classpath) and apply it in `android/app/build.gradle.kts`.
3. Add `firebase_core` and `firebase_crashlytics` to `pubspec.yaml`; run `flutter pub get`.
4. Update `main.dart`: `await Firebase.initializeApp()` before `setupLocator()`; chain Crashlytics into `FlutterError.onError` and `runZonedGuarded` catch block.
5. Write Flutter BLoC/Cubit tests (3 files).
6. Write backend service tests (3 files) and extend `handler_test.go`.
7. Rename `catry_service.go` via `git mv`; fix the `GuessAnimalVoiceScreen` TODO.
8. Run `flutter analyze`, `flutter test`, and `go test ./...` — all must pass before merging.

**Rollback:** Remove the `google-services` plugin lines and revert `main.dart`. No database migration involved; fully reversible.

## Open Questions

- Does the project target iOS for this release? If yes, `GoogleService-Info.plist` must be added to `ios/Runner/` and the Firebase iOS SDK initialised — not in scope here but should be tracked.
- Should Crashlytics user identifiers (e.g., user ID) be set after login to correlate crashes with accounts? Low-effort add-on, deferred to a follow-up change.
