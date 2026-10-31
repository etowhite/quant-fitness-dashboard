import com.android.build.api.variant.LibraryAndroidComponentsExtension
import com.android.build.gradle.LibraryExtension

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
}
subprojects {
    // Keep every Android library on the same installed SDK, including the
    // integration_test plugin whose Flutter default currently points to 36.
    plugins.withId("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension> {
            finalizeDsl { it.compileSdk = 35 }
        }
    }
    afterEvaluate {
        extensions.findByType<LibraryExtension>()?.compileSdk = 35
    }
    if (name == "integration_test") {
        configurations.configureEach {
            resolutionStrategy.force(
                "androidx.test:runner:1.6.2",
                "androidx.test:rules:1.6.1",
                "androidx.test:core:1.6.1",
                "androidx.test.espresso:espresso-core:3.6.1"
            )
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
