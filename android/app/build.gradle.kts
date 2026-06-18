plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 1. Updated from com.example to your own brand namespace
    namespace = "com.cloudnex.pdfpro"
    
    // 2. Updated to latest requirements for AndroidX dependencies
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // 3. Updated your unique Application ID
        applicationId = "com.cloudnex.pdfpro"
        
        // 4. Force a safe minimum SDK (PDF tools usually need API 23+)
        minSdk = 25
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