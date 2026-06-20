# Flutter-specific ProGuard rules.
# See https://flutter.dev/docs/deployment/android#enabling-r8
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.FlutterMain {
   <methods>;
}
-keep class io.flutter.plugin.common.** {
   <fields>;
   <methods>;
}
-keep class io.flutter.plugin.platform.** {
   <fields>;
   <methods>;
}
-keep class io.flutter.plugin.editing.** {
   <fields>;
   <methods>;
}
-keep class io.flutter.plugins.firebase.core.** {
   <methods>;
}
# Keep the following classes for application-specific code.
# -keep class com.example.myapp.** { *; }
