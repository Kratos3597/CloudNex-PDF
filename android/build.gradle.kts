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
            // Fix for "Namespace not specified" error in older plugins like isar_flutter_libs
            if (extension.namespace == null) {
                extension.namespace = when (project.name) {
                    "isar_flutter_libs" -> "dev.isar.isar_flutter_libs"
                    "path_provider_android" -> "io.flutter.plugins.pathprovider"
                    else -> "com.example.${project.name.replace("-", "_")}"
                }
            }

            extension.compileSdkVersion(35)
            extension.defaultConfig {
                targetSdkVersion(35)
            }
        }
    }
}

// Correctly register the clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}