plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

fun resolveSigningValue(propertyKey: String, envKey: String): String? {
    val envValue = System.getenv(envKey)?.trim()
    if (!envValue.isNullOrEmpty()) {
        return envValue
    }

    val propertyValue = keystoreProperties.getProperty(propertyKey)?.trim()
    if (propertyValue.isNullOrEmpty() || propertyValue.startsWith("REPLACE_WITH_")) {
        return null
    }

    return propertyValue
}

val releaseStoreFilePath = resolveSigningValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseKeyAlias = resolveSigningValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = resolveSigningValue("keyPassword", "ANDROID_KEY_PASSWORD")
val releaseStorePassword = resolveSigningValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val hasReleaseSigning = listOf(
    releaseStoreFilePath,
    releaseKeyAlias,
    releaseKeyPassword,
    releaseStorePassword,
).all { !it.isNullOrEmpty() }

android {
    namespace = "com.iskenkenya.onepanel_client"
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
        applicationId = "com.iskenkenya.onepanel_client"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = rootProject.file(requireNotNull(releaseStoreFilePath))
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            // Use upload keystore when available; keep local release builds working without secrets.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
