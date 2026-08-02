# FILE: android/app/proguard-rules.pro

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQFLite
-keep class com.tekartik.sqflite.** { *; }

# Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Tesseract OCR
-keep class com.rmtheis.** { *; }

# Hive
-keep class com.hivedb.** { *; }

# General
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
