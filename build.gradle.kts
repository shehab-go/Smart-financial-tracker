plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    id("org.jlleitschuh.gradle.ktlint") version "12.1.1"
}

allprojects {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")
}
