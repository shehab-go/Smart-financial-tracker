# Data models used for serialization (Gson/Room)
-keep class com.financial.tracker.module.data.** { *; }

# Public API must remain intact
-keep class com.financial.tracker.module.FinancialTrackerClient { *; }

# Keep annotations for Room and Gson
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
