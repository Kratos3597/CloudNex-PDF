buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.21")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Correctly set build directory
rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
    
    // Force consistency for all plugins
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

// Correctly register the clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}