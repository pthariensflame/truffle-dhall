dependencies {
    implementation(project("ast"))
    api(project("evaluation"))
    runtimeOnly(project("shell"))
    api(project("parser"))
    implementation(project(":truffle-grammars"))
}
