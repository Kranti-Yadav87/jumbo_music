import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing: create android/key.properties (see README). Falls back to
// the debug key only when it is missing, so local `flutter run --release` works.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.jumbomusic.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.jumbomusic.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val bundledKeystore = file("debug.keystore")
        if (bundledKeystore.exists()) {
            getByName("debug") {
                storeFile = bundledKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }

        if (keystorePropertiesFile.exists()) {
            val rawStoreFile = (keystoreProperties["storeFile"] as? String)?.trim()
            val resolvedStoreFile = if (rawStoreFile != null) {
                val appFile = file(rawStoreFile)
                val rootFile = rootProject.file(rawStoreFile)
                if (appFile.exists()) appFile else if (rootFile.exists()) rootFile else null
            } else null

            if (resolvedStoreFile != null && resolvedStoreFile.exists()) {
                create("release") {
                    keyAlias = (keystoreProperties["keyAlias"] as String).trim()
                    keyPassword = (keystoreProperties["keyPassword"] as String).trim()
                    storeFile = resolvedStoreFile
                    storePassword = (keystoreProperties["storePassword"] as String).trim()
                }
            }
        }
    }


    buildTypes {
        release {
            signingConfig = if (signingConfigs.findByName("release") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
