#!/bin/bash

# iOS Version Update Script
# Updates version and build number in iOS project
# Usage: ./update_version.sh <version> <build_number>
# Example: ./update_version.sh 1.0.0 1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ "$#" -lt 1 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: $0 <version> [build_number]"
    echo "Example: $0 1.0.0 1"
    exit 1
fi

VERSION=$1
BUILD_NUMBER=${2:-1}

# Validate version format (semantic versioning)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format${NC}"
    echo "Version must be in format: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
    exit 1
fi

# Validate build number
if ! [[ $BUILD_NUMBER =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid build number${NC}"
    echo "Build number must be a positive integer"
    exit 1
fi

echo -e "${GREEN}Updating iOS version...${NC}"
echo "Version: $VERSION"
echo "Build Number: $BUILD_NUMBER"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$IOS_DIR")"

# Update pubspec.yaml
PUBSPEC_FILE="$PROJECT_ROOT/pubspec.yaml"
if [ -f "$PUBSPEC_FILE" ]; then
    echo -e "${YELLOW}Updating pubspec.yaml...${NC}"
    
    # Create backup
    cp "$PUBSPEC_FILE" "$PUBSPEC_FILE.bak"
    
    # Update version line
    sed -i.tmp "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" "$PUBSPEC_FILE"
    rm "$PUBSPEC_FILE.tmp"
    
    echo -e "${GREEN}✓ Updated pubspec.yaml${NC}"
else
    echo -e "${RED}Error: pubspec.yaml not found${NC}"
    exit 1
fi

# Update Info.plist (if needed for manual verification)
INFO_PLIST="$IOS_DIR/Runner/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo -e "${YELLOW}Verifying Info.plist...${NC}"
    
    # Check if version variables are present
    if grep -q "FLUTTER_BUILD_NAME" "$INFO_PLIST" && grep -q "FLUTTER_BUILD_NUMBER" "$INFO_PLIST"; then
        echo -e "${GREEN}✓ Info.plist correctly configured to use Flutter version${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Info.plist may not be using Flutter version variables${NC}"
    fi
fi

# Update Xcode project (optional - usually handled by Flutter)
echo -e "${YELLOW}Note: Xcode project will use version from pubspec.yaml via Flutter${NC}"

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Version Update Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Version: $VERSION"
echo "Build Number: $BUILD_NUMBER"
echo ""
echo "Next steps:"
echo "1. Commit the changes: git add pubspec.yaml && git commit -m 'Bump version to $VERSION ($BUILD_NUMBER)'"
echo "2. Tag the release: git tag v$VERSION"
echo "3. Build the app: flutter build ios --release"
echo ""

# Restore backup option
echo -e "${YELLOW}Backup created at: $PUBSPEC_FILE.bak${NC}"
echo "To restore: mv $PUBSPEC_FILE.bak $PUBSPEC_FILE"
