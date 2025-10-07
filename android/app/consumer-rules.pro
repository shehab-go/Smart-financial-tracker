# Consumer ProGuard rules for the app

# Keep all Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep SQLite classes
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep Gson classes if used
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Keep model classes (adjust package name as needed)
-keep class com.ramzi.debit_credit_app.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep crash reporting
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile