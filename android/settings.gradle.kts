pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val sdkPath = properties.getProperty("flutter.sdk")
            requireNotNull(sdkPath) { "flutter.sdk not set in local.properties" }
            sdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ STABLE VERSIONS (MATCHING FLUTTER REQUIREMENTS)
    id("com.android.application") version "8.11.1" apply false
    id("com.android.library") version "8.11.1" apply false

    // ✅ STABLE KOTLIN FOR FLUTTER
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}
include(":app")