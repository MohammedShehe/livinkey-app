# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
# Play Core (deferred components are not used)
-dontwarn com.google.android.play.core.**
# Firebase / Google Play services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
# Secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
# Keep line numbers for readable crash reports
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature
