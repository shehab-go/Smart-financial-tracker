plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    id("maven-publish")
}

android {
    namespace = "com.financial.tracker.module"
    compileSdk = 35

    defaultConfig {
        minSdk = 24

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("proguard-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)

    // Coroutines
    implementation(libs.kotlinx.coroutines.android)

    // Gson
    implementation(libs.gson)

    // Flutter Embedding (compileOnly so host app provides it at runtime)
    compileOnly(libs.flutter.embedding.release.v1008bf2090718fea3655f466049a757f823898f0ad1)
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.github.shehab-go"
                artifactId = "wallet-events"
                version = "1.1.0"

                pom {
                    name.set("Smart Financial Tracker")
                    description.set("A powerful Android library for secure and dynamic financial transaction parsing from notifications.")
                    url.set("https://github.com/shehab-go/smart-financial-tracker")
                    licenses {
                        license {
                            name.set("The Apache License, Version 2.0")
                            url.set("http://www.apache.org/licenses/LICENSE-2.0.txt")
                        }
                    }
                    developers {
                        developer {
                            id.set("shehab-go")
                            name.set("Shehab Go")
                            email.set("shehab.go.dev@gmail.com")
                        }
                    }
                    scm {
                        connection.set("scm:git:github.com/shehab-go/smart-financial-tracker.git")
                        developerConnection.set("scm:git:ssh://github.com/shehab-go/smart-financial-tracker.git")
                        url.set("https://github.com/shehab-go/smart-financial-tracker/tree/main")
                    }
                }
            }
        }
        repositories {
            maven {
                name = "GitHubPackages"
                url = uri("https://maven.pkg.github.com/shehab-go/smart-financial-tracker")
                credentials {
                    username = System.getenv("GITHUB_ACTOR")
                    password = System.getenv("GITHUB_TOKEN")
                }
            }
        }
    }
}
