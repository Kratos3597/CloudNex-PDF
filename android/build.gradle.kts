import com.android.build.gradle.BaseExtension

buildscript {
    repositories {
        google()
        mavenCentral()
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
        if (extension is BaseExtension) {
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