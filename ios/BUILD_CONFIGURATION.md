# iOS Build and Signing Configuration

This document describes the iOS build configuration and signing setup for the Knowvas Flutter client.

## Build Configurations

The project supports three build configurations:
- **Debug**: For development and testing
- **Profile**: For performance profiling
- **Release**: For production builds

## Version and Build Number

Version and build numbers are managed in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

- **Version**: 1.0.0 (FLUTTER_BUILD_NAME)
- **Build Number**: 1 (FLUTTER_BUILD_NUMBER)

These values are automatically injected into the iOS build via `Info.plist`:
- `CFBundleShortVersionString`: $(FLUTTER_BUILD_NAME)
- `CFBundleVersion`: $(FLUTTER_BUILD_NUMBER)

## Code Signing

### Development Signing

For local development and testing:

1. **Automatic Signing** (Recommended for development):
   - Open `Runner.xcworkspace` in Xcode
   - Select the Runner target
   - Go to "Signing & Capabilities" tab
   - Enable "Automatically manage signing"
   - Select your development team

2. **Manual Signing**:
   - Disable "Automatically manage signing"
   - Select provisioning profile manually
   - Ensure certificate is installed in Keychain

### Production Signing

For App Store distribution:

1. **Required Certificates**:
   - Apple Distribution Certificate
   - App Store Provisioning Profile

2. **Environment Variables** (for CI/CD):
   ```bash
   # Certificate and provisioning profile (base64 encoded)
   IOS_CERTIFICATE_BASE64=<base64-encoded-p12-certificate>
   IOS_CERTIFICATE_PASSWORD=<certificate-password>
   IOS_PROVISIONING_PROFILE_BASE64=<base64-encoded-mobileprovision>
   
   # App Store Connect API (for automated uploads)
   APP_STORE_CONNECT_API_KEY_ID=<key-id>
   APP_STORE_CONNECT_ISSUER_ID=<issuer-id>
   APP_STORE_CONNECT_API_KEY_BASE64=<base64-encoded-p8-key>
   ```

3. **CI/CD Setup**:
   - Store certificates and profiles as GitHub Secrets
   - Use fastlane or xcodebuild for automated builds
   - See `.github/workflows/ci.yml` for CI configuration

## Bundle Identifier

The app bundle identifier is: `com.knowvas.flutterClient`

This can be changed in:
- Xcode: Runner target → General → Bundle Identifier
- Or by editing `ios/Runner.xcodeproj/project.pbxproj`

## App Capabilities

The following capabilities are configured in `Info.plist` and Xcode:

### 1. Background Modes
Required for:
- Background audio playback (audiobooks)
- Background downloads
- Remote notifications

To enable in Xcode:
1. Select Runner target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Background Modes"
5. Enable:
   - ✅ Audio, AirPlay, and Picture in Picture
   - ✅ Background fetch
   - ✅ Remote notifications

### 2. Push Notifications
Required for:
- New content notifications
- Reading reminders
- Social interactions

To enable in Xcode:
1. Select Runner target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Push Notifications"

### 3. File Access
Required for:
- Downloading and storing content
- Accessing user documents

Already configured in `Info.plist`:
```xml
<key>UIFileSharingEnabled</key>
<false/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<false/>
```

### 4. Network Access
Required for:
- API communication
- Content downloads

Already configured in `Info.plist` with App Transport Security settings.

## Build Settings

### Deployment Target
- **Minimum iOS Version**: 14.0
- Configured in `Podfile` and Xcode project settings

### Swift Version
- **Swift Language Version**: 5.0
- Configured in Xcode build settings

### Optimization Levels
- **Debug**: No optimization (-Onone)
- **Profile**: Optimize for speed (-O)
- **Release**: Optimize for speed (-O)

## Provisioning Profiles

### Development Profile
- **Type**: iOS App Development
- **Devices**: Registered development devices
- **Usage**: Local testing on physical devices

### Ad Hoc Profile
- **Type**: Ad Hoc
- **Devices**: Specific registered devices
- **Usage**: Beta testing with TestFlight alternatives

### App Store Profile
- **Type**: App Store
- **Devices**: All devices
- **Usage**: App Store distribution

## Creating Provisioning Profiles

### Via Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles
3. Create App ID:
   - Bundle ID: `com.knowvas.flutterClient`
   - Enable capabilities: Push Notifications, Background Modes
4. Create Provisioning Profile:
   - Select profile type (Development/Ad Hoc/App Store)
   - Select App ID
   - Select certificates
   - Select devices (for Development/Ad Hoc)
   - Download profile

### Via Xcode (Automatic)

1. Open `Runner.xcworkspace`
2. Select Runner target
3. Enable "Automatically manage signing"
4. Xcode will create and manage profiles automatically

## Building for Different Configurations

### Debug Build
```bash
flutter build ios --debug
```

### Profile Build
```bash
flutter build ios --profile
```

### Release Build
```bash
flutter build ios --release
```

### Build with Specific Version
```bash
flutter build ios --release --build-name=1.0.0 --build-number=1
```

## Archive and Export

### Via Xcode

1. Open `Runner.xcworkspace`
2. Select "Any iOS Device" as destination
3. Product → Archive
4. Once archived, click "Distribute App"
5. Select distribution method:
   - App Store Connect
   - Ad Hoc
   - Enterprise
   - Development

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

## Export Options

Create `ios/ExportOptions.plist` for automated exports:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

Replace `YOUR_TEAM_ID` with your Apple Developer Team ID.

## Troubleshooting

### Code Signing Errors

**Error**: "No signing certificate found"
- **Solution**: Install Apple Distribution certificate in Keychain Access

**Error**: "Provisioning profile doesn't match"
- **Solution**: Ensure bundle ID matches provisioning profile

**Error**: "Certificate has expired"
- **Solution**: Renew certificate in Apple Developer Portal

### Build Errors

**Error**: "Module not found"
- **Solution**: Run `pod install` in `ios/` directory

**Error**: "Swift version mismatch"
- **Solution**: Update Swift version in Xcode build settings

### Archive Errors

**Error**: "Generic iOS Device not available"
- **Solution**: Select "Any iOS Device" as build destination

**Error**: "Bitcode upload failed"
- **Solution**: Disable bitcode in build settings (deprecated in Xcode 14+)

## CI/CD Integration

### GitHub Actions Example

See `.github/workflows/ci.yml` for complete CI/CD setup.

Key steps:
1. Install certificates and provisioning profiles
2. Run `flutter build ios --release`
3. Archive with xcodebuild
4. Export IPA
5. Upload to App Store Connect (optional)

### Fastlane Integration

For advanced CI/CD, consider using Fastlane:

```ruby
# Fastfile
lane :beta do
  build_app(
    workspace: "ios/Runner.xcworkspace",
    scheme: "Runner",
    export_method: "app-store"
  )
  upload_to_testflight
end
```

## Security Best Practices

1. **Never commit certificates or provisioning profiles** to version control
2. **Use environment variables** for sensitive data in CI/CD
3. **Rotate certificates** regularly
4. **Use separate profiles** for development and production
5. **Enable App Transport Security** (already configured)
6. **Use keychain for secure storage** (already implemented)

## References

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

## Next Steps

1. **Set up Apple Developer Account**: Required for distribution
2. **Create App ID**: In Apple Developer Portal
3. **Generate Certificates**: Development and Distribution
4. **Create Provisioning Profiles**: For each build configuration
5. **Configure Xcode**: Set up signing in Xcode
6. **Test Build**: Create archive and verify
7. **Set up CI/CD**: Configure automated builds (optional)
8. **Submit to App Store**: Follow App Store submission guidelines

