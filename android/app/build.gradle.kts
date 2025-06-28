plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.billwise"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13599879" // ✅ MATCHES your installed version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.billwise"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
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
dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))

    // Firebase Auth
    implementation("com.google.firebase:firebase-auth-ktx")

    // Firebase Firestore
    implementation("com.google.firebase:firebase-firestore-ktx")

    // Optional (if using Google sign-in or analytics, etc.)
    // implementation("com.google.firebase:firebase-analytics-ktx")
}


flutter {
    source = "../.."
}
