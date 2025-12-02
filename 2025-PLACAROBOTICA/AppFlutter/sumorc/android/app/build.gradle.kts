plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // El plugin de Flutter debe ir al final
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sumorc"
    compileSdk = 35   // ✅ Subido a 35

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.sumorc"
        minSdk = 23
        targetSdk = 35   // ✅ Subido a 35
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false   // ⚠️ Para habilitar shrink, poner true
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
