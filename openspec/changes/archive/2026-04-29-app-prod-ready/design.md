## Context

Arunika is a Flutter mobile app (Android/iOS) with a companion backend service located at `/Users/hamim.tohari/Project/arunika backend`. The frontend uses BLoC for state management, a feature-layered architecture (`data/`, `domain/`, `presentation/`), and Mocktail/bloc_test for testing. The backend is a separate project.

Current issues:
1. **Splash screen** — no native splash using the branded `assets/splash.png`.
2. **Dongeng nav buttons** — `left: 12` / `right: 12` fixed positioning on a full-screen `Stack` means the 44 px circular buttons can be partially hidden by device notches, rounded corners, or safe-area insets on narrow phones.
3. **Flutter prod readiness** — likely missing: environment-based API base URL, global error boundary, structured logging, and gaps in unit-test coverage.
4. **Backend prod readiness** — likely missing: input validation, environment config, error handling middleware, security headers, structured logging, and unit tests.

## Goals / Non-Goals

**Goals:**
- Implement a native splash screen using `flutter_native_splash` package with `splash.png` and a background colour that blends with the image's white background.
- Fix the dongeng detail nav buttons to respect safe-area / screen insets so they are never clipped.
- Harden the Flutter app for production (env config, error handling, logging, analytics hooks).
- Add unit tests for Flutter BLoCs, repositories, use-cases, and utilities.
- Harden the backend for production (env config, validation, error handling, security, logging).
- Add backend unit tests covering all service/repository/controller classes across all meaningful scenarios.

**Non-Goals:**
- UI redesign beyond the specific splash and button fixes.
- New features unrelated to production readiness.
- End-to-end or integration tests (unit tests only).
- CI/CD pipeline changes.

## Decisions

### 1. Splash screen — use `flutter_native_splash`

`flutter_native_splash` is the standard Flutter package for generating native splash screens on Android and iOS from a single image and colour config in `pubspec.yaml`. It handles all resolution variants and Android 12 splash API. Alternative (manual XML/storyboard editing) is error-prone and harder to maintain.

Background colour will be `#FFFFFF` (pure white) to match the white areas of `splash.png`, ensuring a seamless blend.

### 2. Dongeng nav buttons — SafeArea / MediaQuery padding

The buttons use `Positioned` with fixed `left: 12` / `right: 12`. On phones with thick notches or narrow aspect ratios the button circle (44 px) can overflow. Fix: wrap each `Positioned` in a `SafeArea`-aware offset using `MediaQuery.of(context).padding` (or simply add `SafeArea` around the Stack child, or increase horizontal inset to `max(12, MediaQuery.of(context).padding.left + 8)` / right equivalent). This is purely a layout change with no logic impact.

### 3. Flutter prod hardening — environment flavours via `--dart-define`

Use `--dart-define=API_BASE_URL=...` (or a `.env`-style approach with `flutter_dotenv`) to decouple base URLs per environment. A global `runZonedGuarded` in `main.dart` plus `FlutterError.onError` captures unhandled errors. A thin `AppLogger` wrapper around `dart:developer` or `logger` package provides levelled logging without third-party lock-in.

### 4. Flutter unit tests — existing test infra

The project already has `bloc_test` and `mocktail`. Tests will cover: all BLoC classes, all repository implementations (mocking HTTP), all use-cases, and utility functions. Target: every public method with at least one happy-path and one error-path test.

### 5. Backend prod hardening and tests

Will be assessed after reading the backend codebase. Common patterns: centralised error-handling middleware, request validation (class-validator / Joi / equivalent), helmet-style security headers, structured JSON logging (Winston/Pino or equivalent), and environment config via dotenv. Unit tests will mock all I/O boundaries (DB, HTTP clients).

## Risks / Trade-offs

- **`flutter_native_splash` version compatibility** → Pin to a version compatible with the current Flutter SDK. Run `flutter pub get` and `dart run flutter_native_splash:create` as part of the task.
- **SafeArea fix side-effects** → Adding padding could shrink the visible tap area on some devices. The 44 px button plus extra offset keeps hit areas accessible. → Verify on multiple screen sizes.
- **Backend unknowns** → The backend codebase has not yet been read. Some hardening items may already be present. → The tasks artifact will be refined after codebase inspection during implementation.
- **Test flakiness** → BLoC tests that rely on async streams must use `bloc_test`'s `act`/`expect` properly to avoid timing issues. → Follow established patterns in existing test files.
