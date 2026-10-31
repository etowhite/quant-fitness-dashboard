import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyFile = rootProject.file("key.properties")
require(!releaseKeyFile.exists() || releaseKeyFile.isFile) {
    "android/key.properties must be a regular properties file"
}
val releaseKeys = Properties().apply {
    if (releaseKeyFile.isFile) releaseKeyFile.reader(Charsets.UTF_8).use { load(it) }
}
fun releaseKey(name: String): String = releaseKeys.getProperty(name)
    ?.takeIf { it.isNotBlank() }
    ?: error("Missing $name in android/key.properties")

android {
    namespace = "com.example.smart_fitness_dashboard"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smart_fitness_dashboard"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Both variants use the same private persistent certificate when configured.
        getByName("debug") {
            if (releaseKeyFile.isFile) {
                storeFile = rootProject.file(releaseKey("storeFile"))
                require(storeFile!!.isFile) { "Persistent keystore file does not exist" }
                storePassword = releaseKey("storePassword")
                keyAlias = releaseKey("keyAlias")
                keyPassword = releaseKey("keyPassword")
            }
        }
        create("release") {
            if (releaseKeyFile.isFile) {
                storeFile = rootProject.file(releaseKey("storeFile"))
                require(storeFile!!.isFile) { "Release keystore file does not exist" }
                storePassword = releaseKey("storePassword")
                keyAlias = releaseKey("keyAlias")
                keyPassword = releaseKey("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName(
                if (releaseKeyFile.isFile) "release" else "debug"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
