# Arunika

An interactive children's learning app built with Flutter, featuring AR card scanning, audio fairy tales (dongeng), and child profile management.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Flutter App](#flutter-app)
  - [Backend](#backend)
- [Environment Configuration](#environment-configuration)
- [Running Tests](#running-tests)
- [Building for Release](#building-for-release)
- [Architecture](#architecture)

---

## Overview

Arunika is a mobile app for children and parents. Parents register their child's profile, then the child can:

- **Scan AR cards** — point the camera at a physical card to see a 3D model anchored in the real world, with optional audio narration.
- **Listen to fairy tales (dongeng)** — browse and stream audio stories with page-by-page navigation.
- **Manage profile** — view and edit parent and child information.

The Flutter app communicates with a Go REST API backend backed by PostgreSQL, Redis, and SMTP.

---

## Features

| Feature | Description |
|---|---|
| Splash screen | Native splash with Arunika logo (flutter_native_splash) |
| Authentication | Sign in, sign up, OTP verification, forgot password |
| AR card scanning | QR → 3D GLB model placed on a real surface via ARCore |
| Audio playback | Sound button on placed AR model (just_audio) |
| Fairy tales | Browse, search, paginate, and play multi-page audio stories |
| Child profile | View and edit parent + child info via bottom sheet |
| Structured logging | AppLogger wrapping dart:developer; slog JSON on the backend |
| Error capture | runZonedGuarded + FlutterError.onError in main.dart |

---

## Tech Stack

### Flutter App
- **Flutter** 3.x / **Dart** SDK ^3.8.1
- **State management** — flutter_bloc (BLoC pattern)
- **Navigation** — go_router
- **Networking** — Dio
- **AR** — ar_flutter_plugin_2 (ARCore)
- **QR scanning** — qr_code_scanner_plus
- **Audio** — just_audio
- **Secure storage** — flutter_secure_storage
- **DI** — get_it

### Backend
- **Go** 1.23
- **Framework** — Gin
- **ORM** — GORM (PostgreSQL)
- **Cache / token blacklist** — Redis
- **Email** — SMTP (OTP delivery)
- **Logging** — log/slog (JSON)
- **Migrations** — Flyway

---

## Project Structure

```
arunika_app/                  # Flutter app
├── lib/
│   ├── config/               # AppConfig (API base URL via --dart-define)
│   ├── core/
│   │   ├── auth/             # AuthNotifier
│   │   ├── logger/           # AppLogger
│   │   └── storage/          # SecureStorageToken, LocalProfileStorage
│   ├── data/
│   │   ├── api/              # Dio API clients
│   │   ├── models/           # Request / response models
│   │   └── repositories/     # Repository layer
│   ├── di/                   # get_it locator setup
│   ├── network/              # Dio instance + interceptors
│   ├── presentation/
│   │   ├── navigation/       # go_router AppRouter
│   │   └── screens/          # One folder per screen (bloc + screen + state)
│   │       ├── arscanner/
│   │       ├── dongeng/
│   │       ├── home/
│   │       ├── profile/
│   │       ├── qrscanner/
│   │       ├── signin/
│   │       ├── signup/
│   │       └── ...
│   └── main.dart
├── test/                     # Unit tests (mirrors lib/ structure)
├── assets/
│   └── splash.png
└── android/ ios/

arunika_backend/              # Go backend (separate directory)
├── handlers/                 # Gin HTTP handlers
├── middlewares/              # JWT auth, error recovery, security headers
├── models/                   # GORM models
├── services/                 # Business logic
├── routes/                   # Router setup
├── utils/                    # JWT helpers
├── config/                   # Env loading
├── db/                       # DB migrations (SQL)
├── templates/                # Email templates
├── .env.example
└── main.go
```

---

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.x (stable) |
| Dart | ^3.8.1 |
| Go | 1.23+ |
| Android Studio / IntelliJ | Latest (with Flutter + Dart plugins) |
| Android SDK | API 28+ (minSdk 28) |
| ARCore-supported device/emulator | Required for AR features |
| PostgreSQL | 14+ |
| Redis | 6+ |

---

## Getting Started

### Flutter App

1. **Clone the repo and install dependencies**

   ```bash
   flutter pub get
   ```

2. **Configure the API base URL**

   The app reads `API_BASE_URL` from `--dart-define` at build/run time. For local development the default is already set in `lib/config/app_config.dart`. To override:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   ```

   > `10.0.2.2` is the Android emulator's alias for `localhost` on the host machine.

3. **Generate native splash assets** (only needed after changing `assets/splash.png`)

   ```bash
   dart run flutter_native_splash:create
   ```

4. **Generate launcher icons** (only needed after changing icon assets)

   ```bash
   dart run flutter_launcher_icons
   ```

5. **Run on a connected device or emulator**

   ```bash
   flutter run
   ```

---

### Backend

1. **Copy the environment file and fill in your values**

   ```bash
   cd "arunika backend"
   cp .env.example .env
   # edit .env with your DB, Redis, JWT, SMTP credentials
   ```

2. **Start PostgreSQL and Redis** (Docker example)

   ```bash
   docker-compose up -d
   ```

3. **Run database migrations**

   ```bash
   # Flyway (configured via flyway.conf)
   flyway migrate
   ```

4. **Start the server**

   ```bash
   go run main.go
   ```

   The server starts on the port defined by `PORT` in `.env` (default `8080`).

---

## Environment Configuration

All required backend environment variables are documented in `.env.example`:

| Variable | Description |
|---|---|
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | PostgreSQL connection |
| `DB_SSLMODE` | `disable` for local, `require` for production |
| `REDIS_HOST` / `REDIS_PORT` / `REDIS_PASSWORD` | Redis connection |
| `JWT_SECRET` | HS256 signing secret — **minimum 32 characters** |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` | Outgoing email (OTP) |
| `APP_DOMAIN` | Public app URL (used in email links) |
| `PORT` | HTTP listen port (default `8080`) |

The backend will **exit with a clear error message** at startup if any required variable is missing.

---

## Running Tests

### Flutter

```bash
flutter test
```

All 76 unit tests cover BLoC classes, repositories, AppLogger, and AppConfig.

### Backend

```bash
cd "arunika backend"
go test ./...
```

Tests cover services (auth, dongeng, AR, category, user, email), handlers, JWT utilities, and JWT middleware using `sqlmock` and `miniredis`.

---

## Building for Release

### Android APK

```bash
# Single universal APK
flutter build apk --release

# Per-ABI split APKs (smaller download size)
flutter build apk --split-per-abi --release
```

Output: `build/app/outputs/flutter-apk/`

> **Note:** Do not enable Gradle-level ABI splits (`splits { abi }`) — use Flutter's `--split-per-abi` flag instead. Gradle-level splits produce filenames that the Flutter tool cannot locate.

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

### Signing

Create `android/key.properties` with your keystore details (see `android/app/build.gradle.kts` for the expected keys: `keyAlias`, `keyPassword`, `storeFile`, `storePassword`). Without this file the build falls back to debug signing.

---

## Architecture

The Flutter app follows a layered BLoC architecture:

```
UI (screens)
    │  events
    ▼
BLoC (business logic + state)
    │  calls
    ▼
Repository (data access interface)
    │  calls
    ▼
API / Storage (Dio, SharedPreferences, SecureStorage)
```

- **Dependency injection** is handled by `get_it` via `lib/di/locator.dart`.
- **Navigation** uses `go_router` with a centralised `AppRouter`.
- **Error handling** — all uncaught async errors are routed through `runZonedGuarded` and `FlutterError.onError` to `AppLogger`.
- **API base URL** is injected at build time via `--dart-define=API_BASE_URL=...` and read from `AppConfig.apiBaseUrl`.

The Go backend follows a handler → service → model layering:

```
Gin router
    │
JWT middleware → handler
                    │
                 service (business logic)
                    │
                 GORM model (PostgreSQL) / Redis
```

- Panics are caught by `ErrorMiddleware` and returned as JSON 500.
- Security headers (`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`) are added by `SecurityHeadersMiddleware`.
- Structured JSON logs are emitted via `log/slog`.
