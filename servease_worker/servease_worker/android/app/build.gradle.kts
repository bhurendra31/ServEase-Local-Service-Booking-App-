plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin (must be AFTER android & kotlin)
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.servease_worker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true // 🔥 REQUIRED
}

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.servease_worker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // For now use debug signing
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
