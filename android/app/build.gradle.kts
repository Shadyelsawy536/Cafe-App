import java.util.Base64

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Values passed with `flutter build ... --dart-define-from-file=...`.
// Flutter forwards them to Gradle as the base64 "dart-defines" property.
val dartDefines: Map<String, String> =
    if (project.hasProperty("dart-defines")) {
        (project.property("dart-defines") as String)
            .split(",")
            .mapNotNull { item ->
                val decoded = String(Base64.getDecoder().decode(item), Charsets.UTF_8)
                val idx = decoded.indexOf("=")
                if (idx > 0) decoded.substring(0, idx) to decoded.substring(idx + 1) else null
            }
            .toMap()
    } else {
        emptyMap()
    }

android {
    namespace = "com.example.cafe_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = dartDefines["ANDROID_APPLICATION_ID"]
            ?: error("Missing ANDROID_APPLICATION_ID. Build through tool/hubdine_build.dart with the restaurant config.")
        manifestPlaceholders["appName"] = dartDefines["APP_NAME"]
            ?: error("Missing APP_NAME. Build through tool/hubdine_build.dart with the restaurant config.")
        manifestPlaceholders["oauthRedirectScheme"] = dartDefines["OAUTH_REDIRECT_SCHEME"]
            ?: error("Missing OAUTH_REDIRECT_SCHEME. Set it in config/restaurants/<slug>/restaurant.json.")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
