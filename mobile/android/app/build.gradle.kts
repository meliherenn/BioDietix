import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.biodietix.biodietix_mobile"
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
        applicationId = "com.biodietix.biodietix_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "BioDietix")
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "BioDietix Dev")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "BioDietix")
        }
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

fun decodedDartDefines(): Map<String, String> {
    val encoded = project.findProperty("dart-defines")?.toString().orEmpty()
    if (encoded.isBlank()) return emptyMap()
    return encoded.split(",").mapNotNull { value ->
        runCatching {
            val decoded = String(Base64.getDecoder().decode(value))
            val separator = decoded.indexOf('=')
            if (separator <= 0) null else decoded.substring(0, separator) to decoded.substring(separator + 1)
        }.getOrNull()
    }.toMap()
}

gradle.taskGraph.whenReady {
    val requestedTasks = gradle.startParameter.taskNames.joinToString(" ")
    val buildingProd = requestedTasks.contains("Prod", ignoreCase = true)
    val buildingDev = requestedTasks.contains("Dev", ignoreCase = true)
    val expectedFlavor = when {
        buildingProd -> "prod"
        buildingDev -> "dev"
        else -> null
    }
    if (expectedFlavor != null) {
        val dartDefines = decodedDartDefines()
        val dartFlavor = dartDefines["FLAVOR"]
        if (dartFlavor != expectedFlavor) {
            throw GradleException(
                "Android flavor '$expectedFlavor' requires --dart-define=FLAVOR=$expectedFlavor " +
                    "so Firebase App Check selects the matching provider.",
            )
        }
        if (expectedFlavor == "prod" && dartDefines["BIODIETIX_APP_CHECK_ENABLED"] == "false") {
            throw GradleException("App Check cannot be disabled for a production build.")
        }
    }

    val buildingRelease = allTasks.any { it.name.contains("Release", ignoreCase = true) }
    if (buildingRelease && !rootProject.file("key.properties").exists()) {
        throw GradleException("Release signing requires mobile/android/key.properties.")
    }
}

flutter {
    source = "../.."
}
