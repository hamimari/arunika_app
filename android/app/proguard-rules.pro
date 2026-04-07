# ── QR Code Scanner (qr_code_scanner_plus) ───────────────────────────────────
-keep class net.touchcapture.qr.flutterqrplus.** { *; }
-dontwarn net.touchcapture.qr.flutterqrplus.**

# ZXing Android Embedded (camera preview + barcode scanning UI)
-keep class com.journeyapps.barcodescanner.** { *; }
-dontwarn com.journeyapps.barcodescanner.**

# ZXing core (barcode decoding)
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**

# ── ARCore / Sceneform ────────────────────────────────────────────────────────
-keep class com.google.ar.** { *; }
-keep interface com.google.ar.** { *; }
-dontwarn com.google.ar.**

# ── SceneView (ar_flutter_plugin_2 dependency) ───────────────────────────────
-keep class io.github.sceneview.** { *; }
-dontwarn io.github.sceneview.**

# ── ar_flutter_plugin_2 (gordonwong wrapper) ─────────────────────────────────
-keep class com.gordonwong.** { *; }
-dontwarn com.gordonwong.**

# ── OkHttp3 (used by Dio for HTTP calls) ─────────────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Retrofit2 (optional, in case added in future) ────────────────────────────
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# ── Flutter embedding ─────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep interface io.flutter.** { *; }
-dontwarn io.flutter.**

# ── Keep native method names ─────────────────────────────────────────────────
-keepclassmembers class * {
    native <methods>;
}

# ── Serialization (Gson / JSON reflection used by Dio) ───────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
