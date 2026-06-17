plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.pan123ng.pan123next"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.pan123ng.pan123next"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ---- Go downloader backend (gomobile AAR) ----
val goServerDir = "${project.rootDir.parentFile}/server"
val goAarOutput = "${project.rootDir}/app/libs/downloader.aar"

tasks.register<Exec>("buildGoBackend") {
    description = "Build Go downloader backend AAR via gomobile"
    workingDir = file(goServerDir)

    // Only run if gomobile is available
    val gomobilePath: String? by lazy {
        try {
            org.apache.tools.ant.taskdefs.condition.Os.isFamily("windows")
            val result = ByteArrayOutputStream()
            exec {
                commandLine("where", "gomobile")
                standardOutput = result
            }
            result.toString().trim()
        } catch (_: Exception) { null }
    }

    commandLine("gomobile", "bind",
        "-target=android",
        "-o", goAarOutput,
        "-androidapi", "21",
        "./mobile"
    )

    isIgnoreExitValue = true
    doLast {
        if (executionResult.get().exitValue != 0) {
            logger.warn("gomobile not found; skipping Go backend build. " +
                "Install with: go install golang.org/x/mobile/cmd/gomobile@latest")
        }
    }
}

tasks.whenTaskAdded {
    if (name.contains("preBuild") || name.contains("compile")) {
        dependsOn("buildGoBackend")
    }
}

dependencies {
    implementation(files("libs/downloader.aar"))
}

flutter {
    source = "../.."
}
