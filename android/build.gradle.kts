// Top-level build file where you can add configuration options common to all sub-projects/modules.

plugins {
    id("com.android.application") version "8.2.1" apply false
    id("com.android.library") version "8.2.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

// This block forces all plugins to agree on the SDK version
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            val androidExt = android as com.android.build.gradle.BaseExtension
            androidExt.compileSdkVersion(36) // Force consistency
            androidExt.defaultConfig {
                targetSdkVersion(36)
            }
        }
    }
}