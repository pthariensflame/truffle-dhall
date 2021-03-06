import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

val kotlinVersion: String by project
val graalVMVersion: String by project
val docsDir: File by project

plugins {
    kotlin("multiplatform")
    `java-library`
    kotlin("kapt")
    id("org.jetbrains.dokka")
    id("com.palantir.graal")
    id("com.hpe.kraal")
    `maven-publish`
    idea
}

allprojects {
    repositories {
        maven { url = uri("https://dl.bintray.com/kotlin/kotlin-eap") }
        maven { url = uri("https://kotlin.bintray.com/kotlinx") }
        mavenCentral()
        jcenter()
        gradlePluginPortal()
    }

    apply {
        plugin("kotlin-multiplatform")
        plugin<JavaLibraryPlugin>()
        plugin("kotlin-kapt")
        plugin("org.jetbrains.dokka")
        plugin("com.palantir.graal")
        plugin<MavenPublishPlugin>()
        plugin("com.hpe.kraal")
        plugin<IdeaPlugin>()
    }

    version = "0.0.0"
    group = "com.pthariensflame.truffle_dhall"

    dependencies {
        components.all {
            if (id.group.startsWith("org.graalvm")) {
                belongsTo("org.graalvm:graalvm-virtual-platform:${id.version}", true)
            }
        }
        implementation(platform(kotlin("bom", kotlinVersion)))
        testImplementation(platform("org.junit:junit-bom:[5.6.1,)"))
    }

    val test: Test by tasks
    test.run {
        useJUnitPlatform {
            this.includeEngines(
                    "junit-jupiter-engine",
                    "junit-vintage-engine"
                               )
        }
    }

    java {
        withJavadocJar()
        withSourcesJar()
        sourceCompatibility = JavaVersion.VERSION_15
    }

    kapt {
        correctErrorTypes = true
        includeCompileClasspath = false
        javacOptions {
            //option("--module-path", javaCompileClasspath)
        }
    }

    kotlin {
        jvm("jdk8") {
            tasks.withType<KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "1.8"
                }
            }
            java {
                targetCompatibility = JavaVersion.VERSION_1_8
            }
        }
        jvm("jdk11") {
            withJava()
            tasks.withType<KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "11"
//                    val compileJava: JavaCompile by tasks
//                    val javaCompileClasspath = compileJava.classpath.asPath
                    freeCompilerArgs += sequenceOf(
//                                "-Xmodule-path=$javaCompileClasspath"
                                                  )
                }
            }
            java {
                targetCompatibility = JavaVersion.VERSION_11
                modularity.inferModulePath.set(true)
            }
        }
    }

    idea {
        module {
            isDownloadJavadoc = true
            isDownloadSources = true
        }
    }

    dependencies {
        implementation(kotlin("stdlib-jdk8"))
        implementation(kotlin("reflect"))
        implementation("org.graalvm.sdk:graal-sdk:$graalVMVersion")
        api("org.graalvm.truffle:truffle-api:$graalVMVersion")
        compileOnly("org.graalvm.truffle:truffle-dsl-processor:$graalVMVersion")
        compileOnly("com.mageddo.nativeimage:reflection-config-generator:[2.3.4,2.4.0)")
        "kapt"("org.graalvm.truffle:truffle-dsl-processor:$graalVMVersion")
        "kapt"("com.mageddo.nativeimage:reflection-config-generator:[2.3.4,2.4.0)")
        implementation("com.ibm.icu:icu4j:[66.1,)")

        testImplementation(kotlin("test"))
        testImplementation(kotlin("test-junit5"))
        testImplementation("org.junit.jupiter:junit-jupiter-api")
        testImplementation("org.junit.jupiter:junit-jupiter-params")
        testImplementation("org.junit.jupiter:junit-jupiter-engine")
        testImplementation("org.junit.vintage:junit-vintage-engine")
        testImplementation("org.graalvm.truffle:truffle-tck:$graalVMVersion")
        testImplementation("org.graalvm.sdk:polyglot-tck:$graalVMVersion")
    }

    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions.apply {
            languageVersion = "1.4"
            apiVersion = "1.4"
            javaParameters = true
            freeCompilerArgs += sequenceOf(
                    "-Xjvm-default=enable",
                    "-Xassertions=jvm",
                    "-Xemit-jvm-type-annotations",
                    "-Xjsr305=strict",
                    "-Xjsr305=under-migration:warn"
                                          )
        }
    }

    graal {
        mainClass("com.pthariensflame.truffle_dhall.shell.DhallMain")
        outputName("truffle-dhall")
        graalVersion(graalVMVersion)
    }

    val dokka: org.jetbrains.dokka.gradle.DokkaTask by tasks
    dokka.apply {
        outputFormat = "html"
        outputDirectory = "$docsDir/dokka"
    }
}

dependencies {
    implementation(project(":truffle-dhall"))
    implementation(project(":truffle-grammars"))
    implementation(kotlin("stdlib-jdk8"))
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            artifactId = "truffle-dhall-bom"
        }
    }
}

idea {
    project {
        jdkName = "SapMachine 15 EA"
    }
}
