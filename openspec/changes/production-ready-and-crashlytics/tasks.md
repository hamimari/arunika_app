## 1. Firebase Crashlytics — Android Setup

- [x] 1.1 Copy `/Users/hamim.tohari/Downloads/google-service.json` to `android/app/google-services.json`
- [x] 1.2 Add `classpath("com.google.gms:google-services:4.4.2")` to `android/build.gradle` project-level `dependencies` block
- [x] 1.3 Apply the plugin in `android/app/build.gradle.kts`: add `id("com.google.gms.google-services")` to the `plugins` block
- [x] 1.4 Add `firebase_core` and `firebase_crashlytics` to `pubspec.yaml` dependencies and run `flutter pub get`
- [ ] 1.5 Verify `flutter build apk --debug` succeeds with no Gradle or dependency errors

## 2. Firebase Crashlytics — Flutter Wiring

- [x] 2.1 In `main.dart`, add `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` inside `runZonedGuarded` before `setupLocator()` (wrap in try/catch that logs to `AppLogger` on failure)
- [x] 2.2 Call `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode)` immediately after `Firebase.initializeApp()`
- [x] 2.3 Chain `FirebaseCrashlytics.instance.recordFlutterFatalError(details)` inside `FlutterError.onError` after the existing `AppLogger.error` call
- [x] 2.4 Add `FirebaseCrashlytics.instance.recordError(error, stack, fatal: true)` in the `runZonedGuarded` catch block after the existing logger call
- [x] 2.5 Verify `flutter analyze` reports zero issues after the wiring

## 3. Flutter — BLoC/Cubit Unit Test Gaps

- [x] 3.1 Create `test/presentation/screens/home/home_dongeng_section_bloc_test.dart` covering `LoadHomeDongeng` happy path (emits `HomeDongengLoading` → `HomeDongengLoaded`) and error path (emits `HomeDongengLoading` → `HomeDongengError`); mock the repository with `mocktail`
- [x] 3.2 Create `test/presentation/screens/home/home_banner_cubit_test.dart` covering `loadBanners` happy path (emits `HomeBannerLoading` → `HomeBannerLoaded`) and failure path (emits `HomeBannerLoading` → `HomeBannerError`)
- [x] 3.3 Create `test/presentation/screens/premium/premium_pack_cubit_test.dart` covering `loadPacks` success (emits loaded state with pack list) and failure (emits error state)
- [x] 3.4 Run `flutter test` and confirm all three new test files pass with no failures

## 4. Flutter — Code Tidy-Up

- [x] 4.1 In `lib/presentation/screens/vocab/guess_animal_voice_screen.dart`, resolve the `// TODO: integrate audioplayer here` by implementing `just_audio`-based playback following the same pattern as `DongengDetailScreen`
- [x] 4.2 Run `flutter analyze` and fix any remaining warnings or hints in the `lib/` directory
- [x] 4.3 Run `flutter test` to confirm the full test suite still passes after tidy-up

## 5. Backend — Service Unit Test Gaps

- [x] 5.1 Create `services/animal_service_test.go`: add `TestGetAllAnimals_Success` (DB mock returns rows → service returns `[]Animal`) and `TestGetAllAnimals_DBError` (DB mock errors → service returns error)
- [x] 5.2 Create `services/payment_service_test.go`: add `TestCreatePayment_Success` (mock insert succeeds → returns payment with ID) and `TestCreatePayment_DBError` (mock insert fails → returns error); add `TestGetPaymentsByUser_Success` and `TestGetPaymentsByUser_DBError`
- [x] 5.3 Create `services/premium_pack_service_test.go`: add `TestGetAllPacks_Success` and `TestGetAllPacks_DBError`; add tests for any other public methods in `PremiumPackService`
- [x] 5.4 Run `go test ./services/...` and confirm all new tests pass

## 6. Backend — Handler Unit Test Gaps

- [x] 6.1 Add `TestAnimalHandler_GetAll_Success` and `TestAnimalHandler_GetAll_ServiceError` to `handlers/handler_test.go` (or a new `animal_handler_test.go`)
- [x] 6.2 Add `TestAuthHandler_Login_Success` and `TestAuthHandler_Login_InvalidCredentials` (401) covering the login endpoint
- [x] 6.3 Add `TestBannerHandler_GetBanners_Success` and `TestBannerHandler_GetBanners_ServiceError`
- [x] 6.4 Add `TestCategoryHandler_GetCategories_Success` and `TestCategoryHandler_GetCategories_ServiceError`
- [x] 6.5 Add `TestDongengHandler_GetAll_Success` and `TestDongengHandler_GetAll_ServiceError`
- [x] 6.6 Add `TestPaymentHandler_CreatePayment_Success` (201) and `TestPaymentHandler_CreatePayment_InvalidBody` (400)
- [x] 6.7 Add `TestUserHandler_GetProfile_Success` and `TestUserHandler_GetProfile_Unauthorized` (401)
- [x] 6.8 Run `go test ./handlers/...` and confirm all new handler tests pass

## 7. Backend — Code Tidy-Up

- [x] 7.1 Rename `services/catry_service.go` to `services/category_service.go` via `git mv` and verify `go build ./...` succeeds
- [x] 7.2 Audit all handler files for any hard-coded secrets, DB credentials, or API keys; replace any found with environment-variable reads matching the `backend-prod-hardening` spec
- [x] 7.3 Run `go vet ./...` and resolve all reported issues
- [x] 7.4 Run `go test ./...` to confirm the full backend test suite passes after tidy-up

## 8. Final Verification

- [x] 8.1 Run `flutter analyze` — expect zero errors and zero warnings
- [x] 8.2 Run `flutter test` — expect all tests pass
- [x] 8.3 Run `go vet ./...` in the backend project — expect no issues
- [x] 8.4 Run `go test ./...` in the backend project — expect all tests pass
- [ ] 8.5 Build a release APK (`flutter build apk --release`) and confirm Crashlytics is initialised in the build log (look for "FirebaseApp successfully started")
