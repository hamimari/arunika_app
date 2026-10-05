import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
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
    namespace = "com.arunika"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.arunika"
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = 9 //latest is 7
        versionName = flutter.versionName
        // Patrol (patrol_test/): native-UI automation for permission dialogs.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
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

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
