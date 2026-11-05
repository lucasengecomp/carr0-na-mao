allprojects {
    repositories {
        google()
        mavenCentral()
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

    // Workaround: forca compileSdk 36 em todos os plugins subproject.
    // flutter_native_splash 2.4.4 fixa compileSdk 31, mas suas AndroidX deps
    // exigem >= 34. Registrado antes do evaluationDependsOn pra garantir que
    // o afterEvaluate seja agendado antes da avaliacao eager.
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            when (ext) {
                is com.android.build.gradle.LibraryExtension -> ext.compileSdk = 36
                is com.android.build.gradle.AppExtension -> ext.compileSdkVersion(36)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
