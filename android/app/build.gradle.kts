plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "it.vtm.vtm_companion"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.vtm.vtm_companion"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Chiave di firma stabile e versionata nel repository.
    //
    // Non è un segreto e non vuole esserlo: serve solo a far sì che ogni
    // build esca firmata allo stesso modo. Con la chiave di debug generata
    // al volo, ogni compilazione su una macchina pulita produce una firma
    // diversa e Android rifiuta di installare l'aggiornamento sopra la
    // versione già presente. Per una pubblicazione sul Play Store servirebbe
    // invece una chiave vera, tenuta fuori dal repository.
    signingConfigs {
        create("release") {
            storeFile = file("vtm-signing.jks")
            storePassword = "vtmcompanion"
            keyAlias = "vtm"
            keyPassword = "vtmcompanion"

            // Con minSdk 24 Gradle userebbe solo lo schema v2. Alcuni
            // installer di sistema (MIUI, EMUI e altre personalizzazioni)
            // pretendono comunque la vecchia firma v1 e altrimenti si
            // fermano con un generico "app non installata". Attivarli tutti
            // e tre non costa nulla e toglie di mezzo il dubbio.
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
