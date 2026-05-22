# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules (updated to cover modern embedding)
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve application classes to avoid obfuscation breaking reflective access
-keep class com.ramzi.debit_credit_app.** { *; }

# Keep annotations and runtime attributes helpful for debugging
-keepattributes *Annotation*,Signature

# Ignore warnings about optional Google Play Core dynamic delivery classes.
# These are only used when Play Store dynamic features/deferred components are enabled.
-dontwarn com.google.android.play.core.**

# If WebView/JS interfaces used, uncomment and specify interface class
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Ignore missing classes from AndroidX Window extensions and Sidecar
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**
