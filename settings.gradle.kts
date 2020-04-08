enableFeaturePreview("GRADLE_METADATA")

pluginManagement {
    repositories {
        gradlePluginPortal()
        maven { url = uri("https://dl.bintray.com/kotlin/kotlin-eap") }
        maven { url = uri("https://kotlin.bintray.com/kotlinx") }
        mavenCentral()
        jcenter()
        maven("https://dl.bintray.com/kotlin/kotlin-eap")
        maven("https://plugins.gradle.org/m2/")
    }

    plugins {
        val kotlinVersion: String by settings

        kotlin("multiplatform") version kotlinVersion
        kotlin("kapt") version kotlinVersion
        id("org.jetbrains.dokka") version "0.10.1"
        id("com.palantir.graal") version "0.6.0-112-gca0b727"
        id("com.hpe.kraal") version "0.0.15"
    }
}

rootProject.name = "truffle-dhall-root"
include("truffle-dhall")
include("truffle-dhall:ast")
include("truffle-dhall:evaluation")
include("truffle-dhall:parser")
include("truffle-dhall:shell")
include("truffle-grammars")
include("truffle-grammars:ast")
include("truffle-grammars:evaluation")
include("truffle-grammars:parser")
