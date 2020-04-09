val graalVMVersion: String by project

plugins {
    application
}

dependencies {
    implementation(project(":truffle-dhall:ast"))
    api(project(":truffle-dhall:evaluation"))
    runtimeOnly(project(":truffle-dhall:shell"))
    api(project(":truffle-dhall:parser"))
    implementation(project(":truffle-grammars"))
    implementation("org.graalvm.sdk:launcher-common:$graalVMVersion")
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
