## ADDED Requirements

### Requirement: Environment-based API configuration
The app SHALL read the API base URL from a compile-time `--dart-define` variable `API_BASE_URL` so that different environments (dev, staging, prod) can be targeted without code changes.

#### Scenario: API base URL resolved from dart-define
- **WHEN** the app is built with `--dart-define=API_BASE_URL=https://api.example.com`
- **THEN** all network requests use `https://api.example.com` as the base URL

#### Scenario: Default fallback URL for development
- **WHEN** the app is built without `API_BASE_URL` defined
- **THEN** a sensible development default URL is used and a warning is logged

### Requirement: Global unhandled error capture
The app SHALL capture all unhandled Flutter framework errors and uncaught async errors and log them, preventing silent failures in production.

#### Scenario: Flutter framework error captured
- **WHEN** a widget throws an unhandled exception during build or layout
- **THEN** the error is caught via `FlutterError.onError` and logged with full stack trace

#### Scenario: Async zone error captured
- **WHEN** an unhandled exception is thrown in a `Future` or `Stream`
- **THEN** the error is caught via `runZonedGuarded` and logged with full stack trace

### Requirement: Structured application logging
The app SHALL provide a single `AppLogger` utility that writes levelled log entries (debug, info, warning, error) so that log output is consistent and filterable.

#### Scenario: Info log written
- **WHEN** `AppLogger.info('message')` is called
- **THEN** an info-level entry is emitted to the log output

#### Scenario: Error log written with stack trace
- **WHEN** `AppLogger.error('message', error, stackTrace)` is called
- **THEN** an error-level entry including the stack trace is emitted to the log output
