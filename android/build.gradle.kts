buildscript {
    repositories {
        google()           // ✅ Needed for Google Services classpath
        mavenCentral()     // ✅ Optional but safe to include
        gradlePluginPortal() // ✅ Optional
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1") // ✅ Firebase plugin
    }
}

// Kotlin DSL no longer needs "allprojects" in most cases, especially with AGP 8+

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
