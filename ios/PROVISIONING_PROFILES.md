# iOS Provisioning Profiles Guide

This guide explains how to create and manage provisioning profiles for the Knowvas Flutter client iOS app.

## Overview

Provisioning profiles are required to run iOS apps on physical devices and distribute them via the App Store. They link your app's bundle identifier, certificates, and devices together.

## Prerequisites

1. **Apple Developer Account**: Enroll at [developer.apple.com](https://developer.apple.com)
2. **Xcode**: Latest version installed
3. **Bundle Identifier**: `com.knowvas.flutterClient`

## Types of Provisioning Profiles

### 1. Development Profile
- **Purpose**: Testing on physical devices during development
- **Certificate**: iOS App Development certificate
- **Devices**: Specific registered devices (up to 100)
- **Validity**: 1 year
- **Distribution**: Not for App Store

### 2. Ad Hoc Profile
- **Purpose**: Beta testing outside TestFlight
- **Certificate**: Apple Distribution certificate
- **Devices**: Specific registered devices (up to 100)
- **Validity**: 1 year
- **Distribution**: Direct installation via tools like Diawi

### 3. App Store Profile
- **Purpose**: App Store distribution
- **Certificate**: Apple Distribution certificate
- **Devices**: All devices
- **Validity**: 1 year
- **Distribution**: App Store only

### 4. Enterprise Profile (Optional)
- **Purpose**: Internal distribution for organizations
- **Certificate**: Apple Distribution (Enterprise) certificate
- **Devices**: All devices in organization
- **Validity**: 1 year
- **Distribution**: Internal only (requires Enterprise account)

## Creating Certificates

### Development Certificate

1. Open **Keychain Access** on Mac
2. Go to **Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority**
3. Enter your email and name
4. Select "Saved to disk"
5. Save the Certificate Signing Request (CSR)

6. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates)
7. Click **+** to create new certificate
8. Select **iOS App Development**
9. Upload the CSR file
10. Download the certificate
11. Double-click to install in Keychain

### Distribution Certificate

1. Follow steps 1-5 above to create CSR
2. In Apple Developer Portal, select **Apple Distribution**
3. Upload CSR and download certificate
4. Install in Keychain

## Creating App ID

1. Go to [Identifiers](https://developer.apple.com/account/resources/identifiers)
2. Click **+** to create new identifier
3. Select **App IDs** → **App**
4. Configure:
   - **Description**: Knowvas Flutter Client
   - **Bundle ID**: Explicit → `com.knowvas.flutterClient`
   - **Capabilities**: Enable the following:
     - ✅ Push Notifications
     - ✅ Background Modes
     - ✅ Associated Domains (if using universal links)
     - ✅ Sign in with Apple (if implementing)
5. Click **Continue** and **Register**

## Registering Devices (for Development/Ad Hoc)

1. Go to [Devices](https://developer.apple.com/account/resources/devices)
2. Click **+** to register new device
3. Enter:
   - **Device Name**: e.g., "John's iPhone 13"
   - **Device ID (UDID)**: Get from Xcode or iTunes
4. Click **Continue** and **Register**

### Finding Device UDID

**Method 1: Xcode**
1. Connect device to Mac
2. Open Xcode → Window → Devices and Simulators
3. Select device
4. Copy "Identifier"

**Method 2: Finder (macOS Catalina+)**
1. Connect device to Mac
2. Open Finder
3. Select device in sidebar
4. Click on device info to reveal UDID

## Creating Provisioning Profiles

### Development Profile

1. Go to [Profiles](https://developer.apple.com/account/resources/profiles)
2. Click **+** to create new profile
3. Select **iOS App Development**
4. Click **Continue**
5. Select App ID: `com.knowvas.flutterClient`
6. Select development certificates (your certificate)
7. Select devices to include
8. Enter profile name: `Knowvas Development`
9. Click **Generate**
10. Download the profile

### App Store Profile

1. Go to [Profiles](https://developer.apple.com/account/resources/profiles)
2. Click **+** to create new profile
3. Select **App Store**
4. Click **Continue**
5. Select App ID: `com.knowvas.flutterClient`
6. Select distribution certificate
7. Enter profile name: `Knowvas App Store`
8. Click **Generate**
9. Download the profile

## Installing Provisioning Profiles

### Method 1: Xcode (Automatic)

1. Open `Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to **Signing & Capabilities** tab
4. Enable **Automatically manage signing**
5. Select your Team
6. Xcode will automatically download and install profiles

### Method 2: Manual Installation

1. Download provisioning profile (.mobileprovision file)
2. Double-click the file
3. Profile will be installed to:
   ```
   ~/Library/MobileDevice/Provisioning Profiles/
   ```

### Method 3: Xcode Manual

1. Open Xcode → Preferences → Accounts
2. Select your Apple ID
3. Click **Download Manual Profiles**

## Configuring Xcode for Signing

### Automatic Signing (Recommended for Development)

1. Open `Runner.xcworkspace`
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Check **Automatically manage signing**
5. Select **Team** from dropdown
6. Xcode handles the rest

### Manual Signing (Required for CI/CD)

1. Open `Runner.xcworkspace`
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Uncheck **Automatically manage signing**
5. For **Debug** configuration:
   - Provisioning Profile: Select development profile
   - Signing Certificate: iOS Developer
6. For **Release** configuration:
   - Provisioning Profile: Select App Store profile
   - Signing Certificate: Apple Distribution

## Environment Variables for CI/CD

For automated builds in CI/CD pipelines:

```bash
# Certificate (base64 encoded .p12 file)
export IOS_CERTIFICATE_BASE64="<base64-encoded-certificate>"
export IOS_CERTIFICATE_PASSWORD="<certificate-password>"

# Provisioning Profile (base64 encoded .mobileprovision)
export IOS_PROVISIONING_PROFILE_BASE64="<base64-encoded-profile>"

# Team ID
export IOS_TEAM_ID="<your-team-id>"

# Bundle Identifier
export IOS_BUNDLE_ID="com.knowvas.flutterClient"
```

### Encoding Files to Base64

```bash
# Encode certificate
base64 -i certificate.p12 -o certificate_base64.txt

# Encode provisioning profile
base64 -i profile.mobileprovision -o profile_base64.txt
```

### Decoding in CI/CD

```bash
# Decode certificate
echo $IOS_CERTIFICATE_BASE64 | base64 --decode > certificate.p12

# Decode provisioning profile
echo $IOS_PROVISIONING_PROFILE_BASE64 | base64 --decode > profile.mobileprovision

# Install certificate
security create-keychain -p "" build.keychain
security import certificate.p12 -k build.keychain -P $IOS_CERTIFICATE_PASSWORD -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

# Install provisioning profile
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
```

## Exporting Certificate for CI/CD

1. Open **Keychain Access**
2. Select **login** keychain
3. Select **My Certificates** category
4. Find your distribution certificate
5. Right-click → **Export**
6. Save as `.p12` file
7. Set a password (save this securely)
8. Encode to base64 for CI/CD

## Troubleshooting

### "No provisioning profiles found"

**Solution**:
1. Verify bundle identifier matches: `com.knowvas.flutterClient`
2. Check profile is installed in `~/Library/MobileDevice/Provisioning Profiles/`
3. Refresh profiles in Xcode: Preferences → Accounts → Download Manual Profiles

### "Certificate not trusted"

**Solution**:
1. Install Apple Worldwide Developer Relations certificate
2. Download from [Apple PKI](https://www.apple.com/certificateauthority/)
3. Install in Keychain Access

### "Profile doesn't include signing certificate"

**Solution**:
1. Ensure certificate is installed in Keychain
2. Regenerate provisioning profile including the certificate
3. Download and install new profile

### "Provisioning profile expired"

**Solution**:
1. Go to Apple Developer Portal
2. Edit the profile
3. Click **Generate** to renew
4. Download and install new profile

### "Code signing identity not found"

**Solution**:
1. Verify certificate is in Keychain Access
2. Check certificate is valid (not expired)
3. Ensure private key is present with certificate

## Profile Management Best Practices

1. **Use Automatic Signing for Development**: Simplifies local development
2. **Use Manual Signing for CI/CD**: Provides control over certificates
3. **Rotate Certificates Annually**: Before expiration
4. **Keep Profiles Updated**: Regenerate when adding devices or capabilities
5. **Secure Certificate Private Keys**: Never commit to version control
6. **Use Different Profiles per Environment**: Development, staging, production
7. **Document Team ID and Bundle ID**: For team reference

## Capabilities Configuration

After creating provisioning profiles, configure capabilities in Xcode:

### Push Notifications

1. Select Runner target → Signing & Capabilities
2. Click **+ Capability**
3. Add **Push Notifications**
4. Ensure capability is enabled in App ID

### Background Modes

1. Select Runner target → Signing & Capabilities
2. Click **+ Capability**
3. Add **Background Modes**
4. Enable:
   - ✅ Audio, AirPlay, and Picture in Picture
   - ✅ Background fetch
   - ✅ Remote notifications

### Associated Domains (Optional)

For universal links:
1. Add **Associated Domains** capability
2. Add domains: `applinks:knowvas.com`

## Verification

### Verify Profile Installation

```bash
# List installed profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# View profile details
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/<profile-uuid>.mobileprovision
```

### Verify Certificate Installation

```bash
# List certificates in keychain
security find-identity -v -p codesigning
```

### Verify App Signing

```bash
# After building, check signature
codesign -dv --verbose=4 build/ios/iphoneos/Runner.app
```

## Resources

- [Apple Developer Portal](https://developer.apple.com/account/)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [App Distribution Guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Provisioning Profile Format](https://developer.apple.com/documentation/bundleresources/entitlements)

## Next Steps

1. ✅ Create Apple Developer account
2. ✅ Generate certificates (Development and Distribution)
3. ✅ Create App ID with required capabilities
4. ✅ Register development devices
5. ✅ Create provisioning profiles
6. ✅ Install profiles in Xcode
7. ✅ Configure signing in Xcode
8. ✅ Test build and archive
9. ✅ Set up CI/CD with profiles
10. ✅ Submit to App Store

