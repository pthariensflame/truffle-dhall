import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

val kotlinVersion: String by project
val graalVMVersion: String by project
val docsDir: File by project

plugins {
    kotlin("multiplatform")
    `java-library`
    kotlin("kapt") apply false
    id("org.jetbrains.dokka") apply false
    id("com.palantir.graal") apply false
    id("com.hpe.kraal") apply false
    `maven-publish`
    `ivy-publish`
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
}

subprojects {
    apply {
        plugin("kotlin-multiplatform")
        plugin("kotlin-kapt")
        plugin<JavaLibraryPlugin>()
        plugin("org.jetbrains.dokka")
        plugin<MavenPublishPlugin>()
        plugin<IvyPublishPlugin>()
        plugin("com.palantir.graal")
        plugin("com.hpe.kraal")
        plugin<IdeaPlugin>()
    }
}

allprojects {
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
}

subprojects {
    val test: Test by tasks
    test.run {
        useJUnitPlatform {
            this.includeEngines(
                    "junit-jupiter-engine",
                    "junit-vintage-engine"
                               )
        }
    }
}

allprojects {
    kotlin {
        jvm() {
            subprojects {
                dependencies {
                    implementation(kotlin("stdlib-jdk8"))
                    implementation(kotlin("reflect"))
                    implementation("org.graalvm.sdk:graal-sdk:$graalVMVersion")
                    implementation("org.graalvm.sdk:launcher-common:$graalVMVersion")
                    api("org.graalvm.truffle:truffle-api:$graalVMVersion")
                    //kapt("org.graalvm.truffle:truffle-dsl-processor:$graalVMVersion")
                    //kapt("com.mageddo.nativeimage:reflection-config-generator:[2.3.4,2.4.0)")
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

                java {
                    release.set(11)
                    withJavadocJar()
                    withSourcesJar()
                }

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
                                "-Xjsr305=under-migration:warn"
//                                "-Xmodule-path=$javaCompileClasspath"
                                                      )
                    }
                }

//                kapt {
//                    correctErrorTypes = true
//                    includeCompileClasspath = false
//                    javacOptions {
//                        //option("--module-path", javaCompileClasspath)
//                    }
//                }

//                graal {
//                    mainClass("com.pthariensflame.truffle_dhall.shell.DhallMain")
//                    outputName("truffle-dhall")
//                    graalVersion(graalVMVersion)
//                }

                val dokka: org.jetbrains.dokka.gradle.DokkaTask by tasks
                dokka.apply {
                    outputFormat = "html"
                    outputDirectory = "$docsDir/dokka"
                }
            }

            allprojects {
                idea {
                    module {
                        jdkName = "GraalVM 11 ($graalVMVersion)".toString()
                    }
                }
            }
        }
    }
}

dependencies {
    api(project("truffle-dhall"))
    implementation(project("truffle-grammars"))
}

// val compileJava: JavaCompile by tasks
// compileJava.modularClasspathHandling.inferModulePath.set(true)
// val javaCompileClasspath = compileJava.classpath.asPath


// application {
//     mainClassName = "com.pthariensflame.truffle_dhall.shell.DhallMain"
// }



