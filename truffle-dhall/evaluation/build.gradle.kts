dependencies {
    api(project(":truffle-dhall:ast"))
}
publishing {
    publications {
        create<MavenPublication>("maven") {
            artifactId = "truffle-dhall-evaluation"
        }
    }
}
