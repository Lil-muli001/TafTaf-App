# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store split / deferred components (not used but referenced by the embedding)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ZegoCloud
-keep class im.zego.** { *; }
-dontwarn im.zego.**

# Riverpod / StateNotifier
-keep class dev.rrousselgit.** { *; }

# Google Maps / Places
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Shared Preferences
-keep class androidx.datastore.** { *; }

# JSON (dart:convert uses native code — no rules needed, but keep model fields)
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent stripping of enums
-keepclassmembers enum * { *; }

# General AndroidX / Material
-keep class androidx.** { *; }
-dontwarn androidx.**
