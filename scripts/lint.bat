@echo off
REM Comprehensive linting script for Flutter, Android, and iOS (Windows)

echo 🔍 Running code linting...

REM Lint Dart code
echo 📱 Linting Dart code...
call dart analyze lib\ test\ integration_test\

REM Lint Android Kotlin code
echo 🤖 Linting Android Kotlin code...
cd android
call gradlew.bat ktlintCheck
cd ..

echo ✅ Linting complete!
