plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 1. Updated from com.example to your own brand namespace
    namespace = "com.cloudnex.pdf_pro_reader"
    
    // 2. Lowered to stable Android 14/15 standards
    compileSdk = 34 
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // 3. Updated your unique Application ID
        applicationId = "com.cloudnex.pdf_pro_reader"
        
        // 4. Force a safe minimum SDK (PDF tools usually need API 23+)
        minSdk = 23 
        targetSdk = 34
        
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