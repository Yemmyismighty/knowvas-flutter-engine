#!/bin/bash

# Comprehensive formatting script for Flutter, Android, and iOS

set -e

echo "🎨 Running code formatting..."

# Format Dart code
echo "📱 Formatting Dart code..."
dart format lib/ test/ integration_test/ --line-length=120

# Format Android Kotlin code
echo "🤖 Formatting Android Kotlin code..."
cd android
./gradlew ktlintFormat
cd ..

# Format iOS Swift code (if swiftformat is installed)
if command -v swiftformat &> /dev/null; then
    echo "🍎 Formatting iOS Swift code..."
    swiftformat ios/Runner --swiftversion 5.7
else
    echo "⚠️  swiftformat not installed. Skipping iOS formatting."
    echo "   Install with: brew install swiftformat"
fi

echo "✅ Formatting complete!"
