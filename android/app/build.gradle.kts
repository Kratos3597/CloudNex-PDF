plugins {
    id("com.android.application")
    // AGP 9+ includes Kotlin support automatically.
    // Removing the explicit plugin prevents the task conflict.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pdf_pro_reader"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.pdf_pro_reader"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}