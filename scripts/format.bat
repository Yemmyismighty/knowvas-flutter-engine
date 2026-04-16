@echo off
REM Comprehensive formatting script for Flutter, Android, and iOS (Windows)

echo 🎨 Running code formatting...

REM Format Dart code
echo 📱 Formatting Dart code...
call dart format lib\ test\ integration_test\ --line-length=120

REM Format Android Kotlin code
echo 🤖 Formatting Android Kotlin code...
cd android
call gradlew.bat ktlintFormat
cd ..

echo ✅ Formatting complete!
