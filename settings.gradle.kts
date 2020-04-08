enableFeaturePreview("GRADLE_METADATA")

pluginManagement {
    repositories {
        gradlePluginPortal()
        maven { url = uri("https://dl.bintray.com/kotlin/kotlin-eap") }
        maven { url = uri("https://kotlin.bintray.com/kotlinx") }
        mavenCentral()
        jcenter()
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
include(
        "truffle-dhall",
        "truffle-dhall:ast",
        "truffle-dhall:evaluation",
        "truffle-dhall:parser",
        "truffle-dhall:shell",
        "truffle-grammars",
        "truffle-grammars:ast",
        "truffle-grammars:evaluation",
        "truffle-grammars:parser"
       )
