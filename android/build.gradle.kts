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

// Correctly set build directory using DirectoryProperty
rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
    project.evaluationDependsOn(":app")
}

// Correctly register the clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}