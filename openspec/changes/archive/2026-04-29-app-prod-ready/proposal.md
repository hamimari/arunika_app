## Why

The Arunika app has several UX issues and gaps in production-readiness that need to be resolved before a stable release: the splash screen does not properly display the branded image, a navigation bug on the dongeng detail screen truncates buttons on narrow devices, and both the Flutter frontend and the separate backend service lack production hardening (error handling, security, configuration) as well as adequate unit-test coverage.

## What Changes

- Replace the current plain splash screen with the branded `splash.png` image, adjusting the background colour to blend with the image's white tones.
- Fix the layout of the Previous/Next navigation buttons on the dongeng detail screen so they remain fully visible on all screen sizes.
- Audit the Flutter codebase for missing production-readiness concerns (env config, error handling, logging, analytics hooks) and add them.
- Add unit tests for every Flutter class that warrants them (repositories, BLoCs/cubits, use-cases, utilities).
- Audit the backend codebase (`/Users/hamim.tohari/Project/arunika backend`) for missing production-readiness concerns (env config, validation, error handling, security headers, logging) and add them.
- Add unit tests for every backend class that warrants them, covering all meaningful scenarios.

## Capabilities

### New Capabilities

- `splash-screen`: Branded splash screen using splash.png with matching background colour.
- `dongeng-navigation-fix`: Responsive Previous/Next navigation buttons on the dongeng detail screen.
- `flutter-prod-hardening`: Production-readiness improvements to the Flutter app (config, error handling, logging).
- `flutter-unit-tests`: Unit-test suite covering Flutter repositories, BLoCs, use-cases, and utilities.
- `backend-prod-hardening`: Production-readiness improvements to the backend service (config, validation, security, logging).
- `backend-unit-tests`: Unit-test suite covering backend services, repositories, controllers, and utilities across all scenarios.

### Modified Capabilities

## Impact

- `assets/splash.png`, `android/`, `ios/` splash configuration files, `pubspec.yaml` (flutter_native_splash or similar).
- `lib/presentation/screens/dongeng/detail/` — layout widget changes.
- `lib/` broadly — any class missing error handling, env wiring, or tests.
- `/Users/hamim.tohari/Project/arunika backend` — all backend source files.
- `test/` directory in both projects will grow significantly.
