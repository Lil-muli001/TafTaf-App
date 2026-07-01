import java.util.Properties

// Load release signing config from key.properties if it exists.
// To generate your keystore run:
//   keytool -genkey -v -keystore android/app/taftaf-release.jks \
//     -keyalg RSA -keysize 2048 -validity 10000 -alias taftaf
// Then create android/key.properties with:
//   storePassword=<your store password>
//   keyPassword=<your key password>
//   keyAlias=taftaf
//   storeFile=app/taftaf-release.jks
val keystoreProps = Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) keystoreFile.inputStream().use { keystoreProps.load(it) }

// Load API keys from secrets.properties (gitignored, never committed).
// See secrets.properties.example for the required keys.
val secretsProps = Properties()
val secretsFile = rootProject.file("secrets.properties")
if (secretsFile.exists()) secretsFile.inputStream().use { secretsProps.load(it) }

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.taftaf.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (keystoreFile.exists()) {
            create("release") {
                keyAlias     = keystoreProps["keyAlias"]     as String
                keyPassword  = keystoreProps["keyPassword"]  as String
                storeFile    = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.taftaf.app"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            secretsProps.getProperty("GOOGLE_MAPS_API_KEY", "")
    }

    buildTypes {
        release {
            signingConfig = if (keystoreFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
