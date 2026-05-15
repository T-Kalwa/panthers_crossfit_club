plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.panthers.crossfit"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.panthers.crossfit"
        // Correction ici : On force le minSdk à 21 pour supporter le NDK moderne
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Ce bloc lit manuellement votre fichier de signature
    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "GymScanne01"
            storeFile = file("C:\\Users\\tegra\\develop\\upload-keystore.jks")
            storePassword = "GymScanne01"
        }
    }

    buildTypes {
        release {
            // On force l'utilisation de la signature de release
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

flutter {
    source = "../.."
}
