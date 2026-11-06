# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn io.flutter.embedding.**

# Google Sign In / Google Play Services Auth
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keepclassmembers class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Auth (usado com Google Sign-In)
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# JSON serialization / Gson
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep application classes that will be instantiated via reflection
-keep class * extends android.app.Application { *; }

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
