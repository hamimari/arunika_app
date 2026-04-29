import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release signing config ─────────────────────────────────────────────────
// Reads from android/key.properties when it exists (production / CI).
// Falls back to debug signing for local dev so `flutter run` and
// `flutter build apk` still work without a keystore.
val keyPropertiesFile = rootProject.file("key.properties")
val hasKeyProperties = keyPropertiesFile.exists()
val keyProperties = Properties()
if (hasKeyProperties) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.example.arunika_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.arunika_app"
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── ABI splits ────────────────────────────────────────────────────────────
    // Disabled here — use `flutter build apk --split-per-abi` at the Flutter
    // level instead, which correctly names the output files that the Flutter
    // tool expects. Enabling Gradle-level splits produces per-ABI filenames
    // (app-arm64-v8a-release.apk) that the Flutter tool cannot locate.

    // ── Signing configs ───────────────────────────────────────────────────────
    signingConfigs {
        if (hasKeyProperties) {
            create("release") {
                keyAlias    = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile   = keyProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // R8 minification + resource shrinking
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Use real release signing when key.properties is present;
            // fall back to debug signing otherwise (local dev / CI without secrets).
            signingConfig = if (hasKeyProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
