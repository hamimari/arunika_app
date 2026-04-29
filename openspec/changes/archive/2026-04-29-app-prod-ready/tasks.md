## 1. Splash Screen

- [x] 1.1 Add `flutter_native_splash` to `pubspec.yaml` dev_dependencies
- [x] 1.2 Add `flutter_native_splash` configuration block to `pubspec.yaml` (image: `assets/splash.png`, background: `#FFFFFF`, android12 background: `#FFFFFF`)
- [x] 1.3 Run `dart run flutter_native_splash:create` to generate native splash assets for Android and iOS
- [x] 1.4 Call `FlutterNativeSplash.preserve(widgetsBinding: ...)` in `main.dart` and `FlutterNativeSplash.remove()` once the app is ready
- [x] 1.5 Verify splash renders correctly on Android emulator and iOS simulator

## 2. Dongeng Navigation Button Fix

- [x] 2.1 In `dongeng_detail_screen.dart`, replace fixed `left: 12` / `right: 12` offsets on the `Positioned` nav buttons with values that account for `MediaQuery.of(context).padding.left` / `.right` (e.g. `max(12, padding.left + 8)`)
- [ ] 2.2 Verify buttons are fully visible and tappable on a narrow-screen device/emulator (e.g. 360 dp width) and on a device with a large notch

## 3. Flutter Production Hardening

- [x] 3.1 Create `lib/config/app_config.dart` that reads `API_BASE_URL` from `--dart-define` with a sensible dev default
- [x] 3.2 Update the network/Dio setup to use `AppConfig.apiBaseUrl` instead of any hard-coded URL
- [x] 3.3 Create `lib/core/logger/app_logger.dart` with `debug`, `info`, `warning`, `error` static methods wrapping `dart:developer` log
- [x] 3.4 Wrap `runApp` in `main.dart` with `runZonedGuarded` to capture uncaught async errors and log them via `AppLogger`
- [x] 3.5 Set `FlutterError.onError` in `main.dart` to log framework errors via `AppLogger`
- [x] 3.6 Review all repository and BLoC `catch` blocks — replace bare `print` statements with `AppLogger.error`
- [x] 3.7 Ensure no API keys, passwords, or secrets are hard-coded in source files; move any found to `--dart-define` or environment config

## 4. Flutter Unit Tests

- [x] 4.1 Write unit tests for `DongengDetailBloc` (initial state, NextPage, PreviousPage, load success, load failure)
- [x] 4.2 Write unit tests for `DongengListBloc` (load success, load failure, empty list)
- [x] 4.3 Write unit tests for `SignInBloc` (success, wrong credentials, network error)
- [x] 4.4 Write unit tests for `SignUpBloc` (success, validation error, server error)
- [x] 4.5 Write unit tests for `OtpBloc` (success, invalid OTP, expiry error)
- [x] 4.6 Write unit tests for `ForgotPasswordBloc` (success, unknown email, server error)
- [x] 4.7 Write unit tests for `ProfileBloc` (load success, load failure, update success)
- [x] 4.8 Write unit tests for `HomeBloc` (load success, load failure)
- [x] 4.9 Write unit tests for `LandingBloc` (success, failure)
- [x] 4.10 Write unit tests for `FairyTalesRepository` (fetch list success/failure, fetch detail success/failure)
- [x] 4.11 Write unit tests for `AuthRepository` (sign-in success/failure, sign-up success/failure, OTP success/failure)
- [x] 4.12 Write unit tests for `UserRepository` (fetch profile success/failure, update profile success/failure)
- [x] 4.13 Write unit tests for `ArRepository` (fetch cards success/failure)
- [x] 4.14 Write unit tests for `AppLogger` utility (verify each level logs without throwing)
- [x] 4.15 Write unit tests for `AppConfig` (verify base URL is resolved from dart-define / fallback)
- [x] 4.16 Run `flutter test` and fix any failing tests

## 5. Backend Production Hardening

- [x] 5.1 Audit `config/config.go` — ensure all required env vars (DB URL, JWT secret, SMTP credentials, etc.) cause a fatal error with a clear message if missing at startup
- [x] 5.2 Add a `.env.example` file listing all required environment variables with placeholder values
- [x] 5.3 Add centralised error-handling middleware in `middlewares/` that catches panics and unhandled errors and returns a consistent JSON error response (no stack trace to client)
- [x] 5.4 Register the error-handling middleware in `routes/router.go` as the outermost middleware
- [x] 5.5 Add input validation to all `handlers/` using an appropriate Go validation library (e.g. `go-playground/validator`) or manual checks — return `400` with a descriptive message on invalid input
- [x] 5.6 Add security headers middleware (X-Content-Type-Options, X-Frame-Options, referrer-policy) in `middlewares/` and register it in the router
- [x] 5.7 Replace any `fmt.Println` / `log.Println` calls in handlers and services with structured logging (e.g. `log/slog` or `zerolog`) that emits JSON with timestamp and level
- [x] 5.8 Ensure `main.go` handles OS interrupt signals gracefully (context cancel / server shutdown with timeout)
- [x] 5.9 Review all SQL queries / ORM calls for potential injection risks; use parameterised queries throughout

## 6. Backend Unit Tests

- [x] 6.1 Write unit tests for `services/ar_service.go` — mock DB/repository layer, cover success and error paths for all public methods
- [x] 6.2 Write unit tests for `services/category_service.go` — success, not-found, and DB-error scenarios
- [x] 6.3 Write unit tests for `services/user_service.go` — fetch profile success/failure, update success/failure, edge cases (not found, duplicate)
- [x] 6.4 Write unit tests for `services/email_service.go` — mock SMTP client, verify email construction and error handling
- [x] 6.5 Expand `services/auth_service_test.go` to cover: token refresh success/failure, logout, password reset request, password reset confirm
- [x] 6.6 Expand `services/dongeng_service_test.go` to cover: empty result set, DB error, fetch single page success/failure
- [x] 6.7 Write unit tests for `handlers/auth_handler.go` — mock service layer, verify correct HTTP status codes for all endpoints
- [x] 6.8 Write unit tests for `handlers/user_handler.go` — mock service, test valid/invalid request bodies
- [x] 6.9 Write unit tests for `handlers/dongeng_handler.go` — mock service, test success and error responses
- [x] 6.10 Write unit tests for `handlers/ar_handler.go` — mock service, test success and error responses
- [x] 6.11 Write unit tests for `handlers/category_handler.go` — mock service, test success and error responses
- [x] 6.12 Write unit tests for `utils/jwt.go` — expand beyond existing `jwt_test.go` to cover expired tokens, invalid signatures, missing claims
- [x] 6.13 Write unit tests for `middlewares/jwt_middleware.go` — valid token passes, missing/invalid/expired token returns 401
- [x] 6.14 Run `go test ./...` in the backend directory and fix any failing tests
