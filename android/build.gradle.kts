allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Ensure all Android library modules define a namespace (required by AGP 8+)
// Some third-party plugins (e.g., whatsapp_share2) ship without it.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.LibraryExtension && androidExt.namespace == null) {
            // Derive a stable namespace from group/name to unblock builds.
            val derivedNamespace = listOfNotNull(project.group?.toString()?.takeIf { it.isNotBlank() }, project.name)
                .joinToString(".")
            androidExt.namespace = derivedNamespace.ifBlank { "com.generated.${project.name}" }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
