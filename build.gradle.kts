import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

val kotlinVersion: String by project
val graalVMVersion: String by project

plugins {
    kotlin("jvm")
    kotlin("kapt")
    `java-library`
    application
    id("org.jetbrains.dokka")
    id("com.palantir.graal")
    id("com.hpe.kraal")
    `maven-publish`
    `ivy-publish`
    idea
}

version = "0.0.0"

val docsDir: File by project

repositories {
    maven { url = uri("https://dl.bintray.com/kotlin/kotlin-eap") }
    maven { url = uri("https://kotlin.bintray.com/kotlinx") }
    mavenCentral()
    jcenter()
}

dependencies {
    components.all {
        if (id.group.startsWith("org.graalvm")) {
            belongsTo("org.graalvm:graalvm-virtual-platform:${id.version}", true)
        }
        if (id.group.startsWith("org.typemeta") && id.name.startsWith("funcj")) {
            belongsTo("org.typemeta:funcj-virtual-platform:${id.version}", true)
        }
    }

    implementation(platform(kotlin("bom", kotlinVersion)))
    implementation(kotlin("stdlib-jdk8"))
    implementation(kotlin("reflect"))
    implementation("org.typemeta:funcj-parser:[0.6.15,)")
    implementation("org.graalvm.sdk:graal-sdk:$graalVMVersion")
    implementation("org.graalvm.sdk:launcher-common:$graalVMVersion")
    api("org.graalvm.truffle:truffle-api:$graalVMVersion")
    kapt("org.graalvm.truffle:truffle-dsl-processor:$graalVMVersion")
    implementation("com.ibm.icu:icu4j:[66.1,)")

    testImplementation(platform("org.junit:junit-bom:[5.6.1,)"))
    testImplementation(kotlin("test"))
    testImplementation(kotlin("test-junit5"))
    testImplementation("org.junit.jupiter:junit-jupiter-api")
    testImplementation("org.junit.jupiter:junit-jupiter-params")
    testImplementation("org.junit.jupiter:junit-jupiter-engine")
    testImplementation("org.junit.vintage:junit-vintage-engine")
    testImplementation("org.graalvm.truffle:truffle-tck:$graalVMVersion")
    testImplementation("org.graalvm.sdk:polyglot-tck:$graalVMVersion")
}
val compileJava: JavaCompile by tasks
compileJava.modularClasspathHandling.inferModulePath.set(true)
val javaCompileClasspath = compileJava.classpath.asPath

kapt {
    correctErrorTypes = true
    includeCompileClasspath = false
    javacOptions {
        option("--module-path", javaCompileClasspath)
    }
}

java {
    release.set(11)
    withJavadocJar()
    withSourcesJar()
}

graal {
    mainClass("com.pthariensflame.truffle_dhall.shell.DhallMain")
    outputName("truffle-dhall")
    graalVersion(graalVMVersion)
}

val compileKotlin: KotlinCompile by tasks
tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions.apply {
        languageVersion = "1.4"
        apiVersion = "1.4"
        javaParameters = true
        jvmTarget = "11"
        freeCompilerArgs += sequenceOf(
                "-Xjvm-default=enable",
                "-Xassertions=jvm",
                "-Xemit-jvm-type-annotations",
                "-Xjsr305=strict",
                "-Xjsr305=under-migration:warn",
                "-Xmodule-path=$javaCompileClasspath"
                                      )
    }
}

application {
    mainClassName = "com.pthariensflame.truffle_dhall.shell.DhallMain"
}

val dokka: org.jetbrains.dokka.gradle.DokkaTask by tasks
dokka.apply {
    outputFormat = "html"
    outputDirectory = "$docsDir/dokka"
}

val test: Test by tasks
test.apply {
    useJUnitPlatform {
        this.includeEngines(
                "junit-jupiter-engine",
                "junit-vintage-engine"
                           )
    }
}
