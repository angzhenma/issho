plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.issho"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.issho"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies { // this dependencies block is needed so that Gradel can fetch these and resolve them.
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    // implementation("com.google.firebase:firebase-auth:22.3.1")
    implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore:25.0.0")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.android.gms:play-services-auth")
}
