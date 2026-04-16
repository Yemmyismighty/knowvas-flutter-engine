# iOS Build Quick Start Guide

Quick reference for building and signing the Knowvas Flutter iOS app.

## Prerequisites

- ✅ macOS with Xcode 14+ installed
- ✅ Flutter SDK installed and configured
- ✅ CocoaPods installed (`sudo gem install cocoapods`)
- ✅ Apple Developer account (for device testing and distribution)

## Quick Setup

### 1. Install Dependencies

```bash
cd knowvas_flutter_client
flutter pub get
cd ios
pod install
cd ..
```

### 2. Open in Xcode

```bash
open ios/Runner.xcworkspace
```

**Important**: Always open `.xcworkspace`, not `.xcodeproj`

### 3. Configure Signing

In Xcode:
1. Select **Runner** target
2. Go to **Signing & Capabilities** tab
3. Enable **Automatically manage signing**
4. Select your **Team**

## Build Commands

### Debug Build (Development)

```bash
# Build for simulator
flutter build ios --debug --simulator

# Build for device
flutter build ios --debug

# Run on connected device
flutter run --debug
```

### Profile Build (Performance Testing)

```bash
# Build for device
flutter build ios --profile

# Run on connected device
flutter run --profile
```

### Release Build (Production)

```bash
# Build for device
flutter build ios --release

# Build with specific version
flutter build ios --release --build-name=1.0.0 --build-number=1
```

## Version Management

### Update Version

```bash
# Using script
./ios/scripts/update_version.sh 1.0.0 1

# Or manually edit pubspec.yaml
# version: 1.0.0+1
```

### Version Format

- **Version Name**: 1.0.0 (semantic versioning)
- **Build Number**: 1 (incremental integer)
- **Format in pubspec.yaml**: `version: 1.0.0+1`

## Code Signing

### Development (Local Testing)

**Automatic Signing** (Recommended):
1. Open `Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Enable "Automatically manage signing"
4. Select your Team

### Production (App Store)

**Manual Signing**:
1. Create certificates in [Apple Developer Portal](https://developer.apple.com/account/)
2. Create provisioning profiles
3. In Xcode: Disable automatic signing
4. Select provisioning profile manually

See [PROVISIONING_PROFILES.md](./PROVISIONING_PROFILES.md) for detailed instructions.

## Creating Archive

### Via Xcode

1. Open `Runner.xcworkspace`
2. Select **Any iOS Device** as destination
3. **Product → Archive**
4. Wait for archive to complete
5. Click **Distribute App**
6. Select distribution method (App Store, Ad Hoc, etc.)

### Via Command Line

```bash
# Build archive
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ios \
  -exportOptionsPlist ios/ExportOptions.plist
```

### Using Build Script

```bash
# Build release with archive and IPA export
./ios/scripts/build_ios.sh release
```

## Testing

### Simulator

```bash
# List available simulators
flutter devices

# Run on specific simulator
flutter run -d "iPhone 14 Pro"
```

### Physical Device

```bash
# List connected devices
flutter devices

# Run on connected device
flutter run -d <device-id>
```

### TestFlight

1. Archive app in Xcode
2. Distribute to App Store Connect
3. Upload to TestFlight
4. Add internal/external testers
5. Submit for review (external testing)

## Common Issues

### "No provisioning profiles found"

**Solution**:
```bash
# Refresh profiles in Xcode
# Xcode → Preferences → Accounts → Download Manual Profiles
```

### "Pod install failed"

**Solution**:
```bash
cd ios
pod repo update
pod install
cd ..
```

### "Module not found"

**Solution**:
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios
```

### "Certificate not trusted"

**Solution**:
1. Download [Apple Worldwide Developer Relations Certificate](https://www.apple.com/certificateauthority/)
2. Install in Keychain Access

### "Build failed with Swift errors"

**Solution**:
1. Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Rebuild

## File Structure

```
ios/
├── Flutter/                    # Flutter configuration
│   ├── Debug.xcconfig         # Debug build settings
│   ├── Release.xcconfig       # Release build settings
│   └── Profile.xcconfig       # Profile build settings
├── Runner/                     # Main app target
│   ├── Info.plist            # App configuration
│   ├── AppDelegate.swift     # App entry point
│   └── Reader/               # Native reader modules
├── Runner.xcworkspace/        # Xcode workspace (open this!)
├── Runner.xcodeproj/          # Xcode project
├── Podfile                    # CocoaPods dependencies
├── ExportOptions.plist        # Archive export configuration
├── scripts/                   # Build scripts
│   ├── build_ios.sh          # Automated build script
│   └── update_version.sh     # Version update script
└── Documentation/
    ├── BUILD_CONFIGURATION.md # Detailed build guide
    ├── PROVISIONING_PROFILES.md # Signing guide
    ├── CAPABILITIES.md        # Capabilities configuration
    └── QUICK_START.md         # This file
```

## Environment Variables (CI/CD)

```bash
# Code signing
export IOS_CERTIFICATE_BASE64="<base64-certificate>"
export IOS_CERTIFICATE_PASSWORD="<password>"
export IOS_PROVISIONING_PROFILE_BASE64="<base64-profile>"
export IOS_TEAM_ID="<team-id>"

# App Store Connect (for upload)
export APP_STORE_CONNECT_API_KEY_ID="<key-id>"
export APP_STORE_CONNECT_ISSUER_ID="<issuer-id>"
export APP_STORE_CONNECT_API_KEY_BASE64="<base64-key>"
```

## Build Configurations

| Configuration | Purpose | Optimization | Debugging |
|--------------|---------|--------------|-----------|
| Debug | Development | None | Full |
| Profile | Performance testing | High | Partial |
| Release | Production | Maximum | None |

## Capabilities

Required capabilities (configured in Xcode):
- ✅ Background Modes (audio, fetch, remote-notification)
- ✅ Push Notifications

See [CAPABILITIES.md](./CAPABILITIES.md) for detailed configuration.

## App Information

- **Bundle ID**: `com.knowvas.flutterClient`
- **Display Name**: Knowvas Flutter Client
- **Minimum iOS**: 14.0
- **Supported Devices**: iPhone, iPad
- **Orientations**: Portrait, Landscape

## Resources

- [BUILD_CONFIGURATION.md](./BUILD_CONFIGURATION.md) - Detailed build configuration
- [PROVISIONING_PROFILES.md](./PROVISIONING_PROFILES.md) - Code signing guide
- [CAPABILITIES.md](./CAPABILITIES.md) - App capabilities setup
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Portal](https://developer.apple.com/account/)

## Next Steps

1. ✅ Install dependencies: `flutter pub get && cd ios && pod install`
2. ✅ Open workspace: `open ios/Runner.xcworkspace`
3. ✅ Configure signing in Xcode
4. ✅ Build and test: `flutter run`
5. ✅ Create archive for distribution
6. ✅ Submit to App Store

## Support

For issues or questions:
1. Check documentation in `ios/` directory
2. Review Flutter iOS documentation
3. Check Apple Developer forums
4. Review Xcode build logs

