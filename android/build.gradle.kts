// Top-level build file
plugins {
    // Keep your environment's versions here (Do not change)
    id("com.android.application") apply false
    id("com.android.library")apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

subprojects {
    afterEvaluate {
        val extension = extensions.findByName("android")
        if (extension is com.android.build.gradle.BaseExtension) {
            extension.compileSdkVersion(36)
            extension.defaultConfig {
                targetSdkVersion(36)
            }
        }
    }
}