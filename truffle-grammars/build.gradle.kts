dependencies {
    implementation(project(":truffle-grammars:ast"))
    api(project(":truffle-grammars:evaluation"))
    api(project(":truffle-grammars:parser"))
    implementation(kotlin("stdlib-jdk8"))
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            artifactId = "truffle-grammars"
        }
    }
}
