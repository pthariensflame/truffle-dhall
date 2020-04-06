plugins {
    kotlin("kapt")
    id("org.jetbrains.dokka")
    id("com.palantir.graal")
    id("com.hpe.kraal")
}

dependencies {
    implementation(project("ast"))
    api(project("evaluation"))
    api(project("parser"))
}

