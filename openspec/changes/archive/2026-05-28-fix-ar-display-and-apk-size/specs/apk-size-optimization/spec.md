## ADDED Requirements

### Requirement: Release build uses Android App Bundle (AAB) format
The production release artifact SHALL be built as an Android App Bundle (AAB) rather than a universal APK, enabling Google Play to deliver per-device optimized APKs.

#### Scenario: AAB produced by release build command
- **WHEN** the developer runs `flutter build appbundle --release`
- **THEN** an `.aab` file SHALL be produced under `build/app/outputs/bundle/release/`

### Requirement: R8 code shrinking enabled for release builds
The release build SHALL enable R8 minification (`isMinifyEnabled = true`) to remove unused code and reduce binary size.

#### Scenario: Minification active in release buildType
- **WHEN** an APK or AAB is built with the `release` build type
- **THEN** `isMinifyEnabled` SHALL be `true` in `android/app/build.gradle.kts`

#### Scenario: Keep rules protect AR and QR libraries from stripping
- **WHEN** R8 processes the release build
- **THEN** classes under `com.google.ar.**`, `io.github.sceneview.**`, `com.gordonwong.**`, and Dio/OkHttp reflection targets SHALL be preserved via `proguard-rules.pro`

### Requirement: Resource shrinking enabled for release builds
The release build SHALL enable Android resource shrinking (`shrinkResources = true`) to remove unused drawables, layouts, and other resources.

#### Scenario: Resource shrinking active in release buildType
- **WHEN** an APK or AAB is built with the `release` build type
- **THEN** `shrinkResources` SHALL be `true` in `android/app/build.gradle.kts`

### Requirement: ABI splits configured for direct APK distribution
When building APKs directly (not AAB), the build SHALL produce per-ABI split APKs for `arm64-v8a`, `armeabi-v7a`, and `x86_64` to reduce individual APK sizes.

#### Scenario: ABI split APKs are generated
- **WHEN** the developer runs `flutter build apk --split-per-abi --release`
- **THEN** separate APK files SHALL be produced for each configured ABI

### Requirement: Release signing uses a dedicated production keystore
The `release` buildType SHALL be signed with a production keystore, not the debug keystore.

#### Scenario: Release build is signed with production key
- **WHEN** an APK or AAB is built with `release` build type and a `key.properties` file or equivalent environment variables are present
- **THEN** the artifact SHALL be signed with the production keystore credentials

#### Scenario: Build fails clearly without signing credentials
- **WHEN** an APK or AAB is built with `release` build type and signing credentials are absent
- **THEN** the build SHALL fail with a clear error message indicating missing signing configuration rather than silently falling back to debug signing

### Requirement: ProGuard rules file exists with required keep rules
A `proguard-rules.pro` file SHALL exist at `android/app/proguard-rules.pro` containing keep rules for all reflective or JNI-dependent libraries used by the app.

#### Scenario: Keep rules file is present
- **WHEN** a developer inspects `android/app/proguard-rules.pro`
- **THEN** the file SHALL exist and contain keep rules for AR, QR scanner, and networking libraries
