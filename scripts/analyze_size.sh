#!/bin/bash

# App Size Analysis Script for Knowvas Flutter Client
# This script builds the app and analyzes its size

set -e

echo "📊 Starting app size analysis..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build Android APK with size analysis
echo ""
echo "${YELLOW}Building Android APK...${NC}"
flutter build apk --release --analyze-size --target-platform android-arm64

# Build Android App Bundle with size analysis
echo ""
echo "${YELLOW}Building Android App Bundle...${NC}"
flutter build appbundle --release --analyze-size

# Build iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "${YELLOW}Building iOS IPA...${NC}"
    flutter build ios --release --no-codesign
else
    echo ""
    echo "${YELLOW}Skipping iOS build (not on macOS)${NC}"
fi

# Display size information
echo ""
echo "${GREEN}=== Build Size Summary ===${NC}"
echo ""

# Android APK size
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "Android APK (arm64): $APK_SIZE"
fi

# Android App Bundle size
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo "Android App Bundle: $AAB_SIZE"
fi

# iOS IPA size (if built)
if [ -f "build/ios/iphoneos/Runner.app" ]; then
    IOS_SIZE=$(du -sh build/ios/iphoneos/Runner.app | cut -f1)
    echo "iOS App: $IOS_SIZE"
fi

echo ""
echo "${GREEN}✅ Size analysis complete!${NC}"
echo ""
echo "For detailed size breakdown, check:"
echo "  - build/app/outputs/flutter-apk/app-release.apk.code-size.json"
echo "  - build/app/outputs/bundle/release/app-release.aab.code-size.json"
echo ""
echo "To view size breakdown in browser:"
echo "  flutter pub global activate devtools"
echo "  flutter pub global run devtools"
echo "  Then open the App Size tool and load the JSON file"
