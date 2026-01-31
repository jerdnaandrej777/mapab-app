# Flutter ProGuard Rules

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Gson (falls von Plugins verwendet)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Supabase / GoTrue
-keep class io.supabase.** { *; }

# OkHttp (Netzwerk)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Hive (lokale Datenbank)
-keep class ** extends com.google.crypto.tink.shaded.protobuf.GeneratedMessageLite { *; }

# Google Play Core (Flutter deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Prevent R8 from removing classes used via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
