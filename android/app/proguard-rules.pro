# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Just Audio & Audio Service Keep Rules
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**
-keep class com.ryanheise.just_audio_background.** { *; }
-dontwarn com.ryanheise.just_audio_background.**
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# MediaCompat & AndroidX Media
-keep class androidx.media.** { *; }
-keep class androidx.media.app.** { *; }
-keep class android.support.v4.media.** { *; }
