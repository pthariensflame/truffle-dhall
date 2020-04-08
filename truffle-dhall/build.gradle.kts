import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    application
    kotlin("jvm") version "1.4-M1"
}

dependencies {
    implementation(project(":truffle-dhall:ast"))
    api(project(":truffle-dhall:evaluation"))
    runtimeOnly(project(":truffle-dhall:shell"))
    api(project(":truffle-dhall:parser"))
    implementation(project(":truffle-grammars"))
    implementation(kotlin("stdlib-jdk8"))
}

application {
    mainClassName = "com.pthariensflame.truffle_dhall.shell.DhallMain"
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            artifactId = "truffle-dhall"
        }
    }
}
repositories {
    maven("https://dl.bintray.com/kotlin/kotlin-eap")
    mavenCentral()
}
val compileKotlin: KotlinCompile by tasks
compileKotlin.kotlinOptions {
    jvmTarget = "1.8"
}
val compileTestKotlin: KotlinCompile by tasks
compileTestKotlin.kotlinOptions {
    jvmTarget = "1.8"
}