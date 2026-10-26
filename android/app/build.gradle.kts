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

// Keep config/restaurants/<slug>/google-services.json as the source of truth.
// This also works when developers invoke flutter run directly with
// --dart-define-from-file=config/restaurants/<slug>/restaurant.json.
val restaurantSlug = dartDefines["SLUG"]
val configuredAndroidId = dartDefines["ANDROID_APPLICATION_ID"]
if (!restaurantSlug.isNullOrBlank() && !configuredAndroidId.isNullOrBlank()) {
    val restaurantConfigDir = rootProject.projectDir.parentFile
        .resolve("config")
        .resolve("restaurants")
        .resolve(restaurantSlug)
    val sourceGoogleServices = restaurantConfigDir.resolve("google-services.json")
    if (!sourceGoogleServices.isFile) {
        error(
            "Missing Firebase config: ${sourceGoogleServices.absolutePath}. " +
                "Keep google-services.json in config/restaurants/$restaurantSlug/."
        )
    }

    val packageNames = Regex("\"package_name\"\\s*:\\s*\"([^\"]+)\"")
        .findAll(sourceGoogleServices.readText())
        .map { it.groupValues[1] }
        .toSet()
    if (configuredAndroidId !in packageNames) {
        error(
            "Firebase package mismatch for $restaurantSlug: expected " +
                "$configuredAndroidId, found $packageNames in " +
                sourceGoogleServices.absolutePath
        )
    }

    val destinationGoogleServices = project.projectDir.resolve("google-services.json")
    sourceGoogleServices.copyTo(destinationGoogleServices, overwrite = true)
    logger.lifecycle(
        "HubDine: loaded google-services.json from config/restaurants/$restaurantSlug/"
    )
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

    signingConfigs {
        create("release") {
            // Codemagic injects these values from its Android keystore reference.
            val keystorePath = System.getenv("CM_KEYSTORE_PATH")
            if (!keystorePath.isNullOrBlank()) {
                storeFile = file(keystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                    ?: error("Missing CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                    ?: error("Missing CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
                    ?: error("Missing CM_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Store builds on CI must use the uploaded release keystore.
            // Keep local release builds usable with the debug key.
            signingConfig = if (System.getenv("CI") == "true") {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
