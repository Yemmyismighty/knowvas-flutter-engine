#!/bin/bash

# iOS Build Script for CI/CD
# Builds and archives iOS app with proper code signing
# Usage: ./build_ios.sh [debug|profile|release]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_MODE=${1:-release}
WORKSPACE="ios/Runner.xcworkspace"
SCHEME="Runner"
ARCHIVE_PATH="build/ios/Runner.xcarchive"
EXPORT_PATH="build/ios/ipa"
EXPORT_OPTIONS="ios/ExportOptions.plist"

# Validate build mode
if [[ ! "$BUILD_MODE" =~ ^(debug|profile|release)$ ]]; then
    echo -e "${RED}Error: Invalid build mode${NC}"
    echo "Usage: $0 [debug|profile|release]"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}iOS Build Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Build Mode: $BUILD_MODE"
echo ""

# Check if running in CI
if [ -n "$CI" ]; then
    echo -e "${YELLOW}Running in CI environment${NC}"
    IS_CI=true
else
    echo -e "${YELLOW}Running in local environment${NC}"
    IS_CI=false
fi

# Function to setup code signing for CI
setup_code_signing() {
    echo -e "${YELLOW}Setting up code signing...${NC}"
    
    # Check for required environment variables
    if [ -z "$IOS_CERTIFICATE_BASE64" ] || [ -z "$IOS_PROVISIONING_PROFILE_BASE64" ]; then
        echo -e "${RED}Error: Missing code signing environment variables${NC}"
        echo "Required: IOS_CERTIFICATE_BASE64, IOS_PROVISIONING_PROFILE_BASE64"
        exit 1
    fi
    
    # Create temporary keychain
    KEYCHAIN_PATH="$RUNNER_TEMP/build.keychain"
    KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
    
    echo "Creating temporary keychain..."
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    
    # Decode and import certificate
    echo "Importing certificate..."
    echo "$IOS_CERTIFICATE_BASE64" | base64 --decode > certificate.p12
    security import certificate.p12 \
        -k "$KEYCHAIN_PATH" \
        -P "${IOS_CERTIFICATE_PASSWORD:-}" \
        -T /usr/bin/codesign \
        -T /usr/bin/security
    
    # Set key partition list
    security set-key-partition-list \
        -S apple-tool:,apple: \
        -s \
        -k "$KEYCHAIN_PASSWORD" \
        "$KEYCHAIN_PATH"
    
    # Add keychain to search list
    security list-keychains -d user -s "$KEYCHAIN_PATH" $(security list-keychains -d user | sed s/\"//g)
    
    # Install provisioning profile
    echo "Installing provisioning profile..."
    PP_PATH="$HOME/Library/MobileDevice/Provisioning Profiles"
    mkdir -p "$PP_PATH"
    echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 --decode > "$PP_PATH/build.mobileprovision"
    
    echo -e "${GREEN}✓ Code signing setup complete${NC}"
}

# Function to cleanup code signing
cleanup_code_signing() {
    if [ "$IS_CI" = true ]; then
        echo -e "${YELLOW}Cleaning up code signing...${NC}"
        
        # Remove temporary keychain
        if [ -n "$KEYCHAIN_PATH" ]; then
            security delete-keychain "$KEYCHAIN_PATH" || true
        fi
        
        # Remove certificate file
        rm -f certificate.p12
        
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    fi
}

# Trap to ensure cleanup runs
trap cleanup_code_signing EXIT

# Setup code signing if in CI
if [ "$IS_CI" = true ] && [ "$BUILD_MODE" = "release" ]; then
    setup_code_signing
fi

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
cd ios
pod install
cd ..
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
flutter clean
rm -rf build/ios
echo -e "${GREEN}✓ Clean complete${NC}"

# Get packages
echo -e "${YELLOW}Getting Flutter packages...${NC}"
flutter pub get
echo -e "${GREEN}✓ Packages retrieved${NC}"

# Build Flutter app
echo -e "${YELLOW}Building Flutter app ($BUILD_MODE)...${NC}"
flutter build ios --$BUILD_MODE --no-codesign
echo -e "${GREEN}✓ Flutter build complete${NC}"

# For release builds, create archive
if [ "$BUILD_MODE" = "release" ]; then
    echo -e "${YELLOW}Creating archive...${NC}"
    
    # Determine configuration
    CONFIGURATION="Release"
    
    # Build archive
    xcodebuild -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        clean archive
    
    echo -e "${GREEN}✓ Archive created${NC}"
    
    # Export IPA
    if [ -f "$EXPORT_OPTIONS" ]; then
        echo -e "${YELLOW}Exporting IPA...${NC}"
        
        xcodebuild -exportArchive \
            -archivePath "$ARCHIVE_PATH" \
            -exportPath "$EXPORT_PATH" \
            -exportOptionsPlist "$EXPORT_OPTIONS" \
            -allowProvisioningUpdates
        
        echo -e "${GREEN}✓ IPA exported${NC}"
        
        # List exported files
        echo ""
        echo "Exported files:"
        ls -lh "$EXPORT_PATH"
    else
        echo -e "${YELLOW}⚠ ExportOptions.plist not found, skipping IPA export${NC}"
    fi
fi

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Build Mode: $BUILD_MODE"

if [ "$BUILD_MODE" = "release" ]; then
    echo "Archive: $ARCHIVE_PATH"
    if [ -f "$EXPORT_PATH/Runner.ipa" ]; then
        echo "IPA: $EXPORT_PATH/Runner.ipa"
        
        # Get IPA size
        IPA_SIZE=$(du -h "$EXPORT_PATH/Runner.ipa" | cut -f1)
        echo "IPA Size: $IPA_SIZE"
    fi
fi

echo ""
echo "Next steps:"
if [ "$BUILD_MODE" = "release" ]; then
    echo "1. Test the IPA on a device"
    echo "2. Upload to TestFlight: xcrun altool --upload-app -f $EXPORT_PATH/Runner.ipa -u <apple-id> -p <app-specific-password>"
    echo "3. Or use Transporter app to upload to App Store Connect"
else
    echo "1. Test the build on a simulator or device"
    echo "2. Run: flutter run --$BUILD_MODE"
fi
echo ""
