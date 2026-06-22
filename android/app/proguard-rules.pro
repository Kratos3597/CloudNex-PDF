# Isar rules
-keep class io.isar.** { *; }
-keep class * extends io.isar.IsarLink { *; }
-keep class * extends io.isar.IsarLinks { *; }
-keep class * extends io.isar.IsarObject { *; }

# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Syncfusion rules
-keep class com.syncfusion.** { *; }

# Path provider rules
-keep class com.baseflow.pathprovider.** { *; }

# Play Core (Deferred Components) - Fixes R8 errors
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ML Kit Text Recognition - Fixes R8 errors
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }

# General missing class warnings to ignore
-dontwarn okio.**
-dontwarn javax.annotation.**
