plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// CI passes credentials as environment variables; passwords never enter a file.
// A fresh local checkout retains debug signing for `flutter run --release`.
val uploadKeyPath = System.getenv("ANDROID_KEYSTORE_PATH")
val requireUploadSigning = System.getenv("REQUIRE_ANDROID_RELEASE_SIGNING") == "true"
val hasUploadSigning = !uploadKeyPath.isNullOrBlank()
fun signingValue(name: String): String = System.getenv(name)
    ?.takeIf { it.isNotBlank() }
    ?: throw GradleException("Missing Android signing environment variable: $name")
if (requireUploadSigning && !hasUploadSigning) {
    throw GradleException("Release deployment requires ANDROID_KEYSTORE_PATH")
}

android {
    namespace = "dev.lauver.bakagames"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.lauver.bakagames"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadSigning) {
            create("upload") {
                storeFile = file(uploadKeyPath!!)
                require(storeFile!!.isFile) { "Android upload keystore does not exist" }
                storePassword = signingValue("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("ANDROID_KEY_ALIAS")
                keyPassword = signingValue("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasUploadSigning) "upload" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
