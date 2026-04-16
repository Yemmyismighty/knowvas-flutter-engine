#!/bin/bash

# Comprehensive linting script for Flutter, Android, and iOS

set -e

echo "🔍 Running code linting..."

# Lint Dart code
echo "📱 Linting Dart code..."
dart analyze lib/ test/ integration_test/

# Lint Android Kotlin code
echo "🤖 Linting Android Kotlin code..."
cd android
./gradlew ktlintCheck
cd ..

# Lint iOS Swift code (if swiftlint is installed)
if command -v swiftlint &> /dev/null; then
    echo "🍎 Linting iOS Swift code..."
    cd ios
    swiftlint lint
    cd ..
else
    echo "⚠️  swiftlint not installed. Skipping iOS linting."
    echo "   Install with: brew install swiftlint"
fi

echo "✅ Linting complete!"
