# iOS App Capabilities Configuration

This document describes the iOS capabilities required for the Knowvas Flutter client and how to configure them.

## Required Capabilities

### 1. Background Modes

**Purpose**: Enable background functionality for audio playback and downloads

**Required for**:
- Audiobook playback while app is in background
- Background content downloads
- Push notification handling

**Configuration**:

1. **In Xcode**:
   - Open `Runner.xcworkspace`
   - Select Runner target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Background Modes"
   - Enable:
     - ✅ Audio, AirPlay, and Picture in Picture
     - ✅ Background fetch
     - ✅ Remote notifications

2. **In Info.plist** (already configured):
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>audio</string>
       <string>fetch</string>
       <string>remote-notification</string>
   </array>
   ```

3. **In App ID** (Apple Developer Portal):
   - Go to Identifiers → Select your App ID
   - Ensure "Background Modes" is enabled

**Implementation Notes**:
- Audio background mode allows audiobook playback to continue when app is backgrounded
- Background fetch enables periodic content updates
- Remote notifications allow push notification handling

### 2. Push Notifications

**Purpose**: Send notifications to users about new content, reminders, and social interactions

**Required for**:
- New content release notifications
- Reading reminders
- Social interaction alerts (follows, reviews)
- Subscription updates

**Configuration**:

1. **In Xcode**:
   - Open `Runner.xcworkspace`
   - Select Runner target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Push Notifications"

2. **In App ID** (Apple Developer Portal):
   - Go to Identifiers → Select your App ID
   - Enable "Push Notifications"
   - Configure certificates for development and production

3. **APNs Certificates**:
   - Create APNs SSL Certificate in Apple Developer Portal
   - Download and install certificate
   - Configure backend with certificate for sending notifications

**Implementation Notes**:
- Use Firebase Cloud Messaging (FCM) or Apple Push Notification service (APNs) directly
- Request notification permission from user at appropriate time
- Handle notification taps to navigate to relevant content

### 3. App Transport Security (ATS)

**Purpose**: Secure network communication

**Configuration** (already in Info.plist):
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

**Settings**:
- `NSAllowsArbitraryLoads`: false (enforce HTTPS)
- `NSAllowsLocalNetworking`: true (allow localhost for development)

**Production Considerations**:
- All API endpoints must use HTTPS
- Consider certificate pinning for enhanced security
- Ensure backend SSL certificates are valid

### 4. Photo Library Access

**Purpose**: Allow users to select profile pictures from photo library

**Configuration** (already in Info.plist):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Knowvas needs access to your photo library to set profile pictures and upload images.</string>
```

**Implementation Notes**:
- Request permission only when user attempts to select photo
- Use `image_picker` Flutter package
- Handle permission denial gracefully

### 5. Camera Access

**Purpose**: Allow users to take profile pictures with camera

**Configuration** (already in Info.plist):
```xml
<key>NSCameraUsageDescription</key>
<string>Knowvas needs access to your camera to take profile pictures.</string>
```

**Implementation Notes**:
- Request permission only when user attempts to use camera
- Use `image_picker` Flutter package
- Handle permission denial gracefully

## Optional Capabilities

### 1. Associated Domains (Universal Links)

**Purpose**: Deep linking from web to app

**Use Cases**:
- Share content links that open in app
- Email magic links for authentication
- Social media content sharing

**Configuration**:

1. **In Xcode**:
   - Add "Associated Domains" capability
   - Add domain: `applinks:knowvas.com`
   - Add domain: `applinks:www.knowvas.com`

2. **On Web Server**:
   - Host `apple-app-site-association` file at:
     ```
     https://knowvas.com/.well-known/apple-app-site-association
     ```
   - File content:
     ```json
     {
       "applinks": {
         "apps": [],
         "details": [
           {
             "appID": "TEAM_ID.com.knowvas.flutterClient",
             "paths": [
               "/content/*",
               "/author/*",
               "/book/*"
             ]
           }
         ]
       }
     }
     ```

### 2. Sign in with Apple

**Purpose**: Allow users to sign in with Apple ID

**Configuration**:

1. **In Xcode**:
   - Add "Sign in with Apple" capability

2. **In App ID**:
   - Enable "Sign in with Apple"

3. **Implementation**:
   - Use `sign_in_with_apple` Flutter package
   - Handle authentication flow
   - Store user credentials securely

### 3. In-App Purchase

**Purpose**: Handle content purchases and subscriptions through Apple

**Configuration**:

1. **In Xcode**:
   - Add "In-App Purchase" capability

2. **In App Store Connect**:
   - Create in-app purchase products
   - Configure pricing and availability

3. **Implementation**:
   - Use `in_app_purchase` Flutter package
   - Implement purchase flow
   - Validate receipts with backend

### 4. iCloud (CloudKit)

**Purpose**: Sync user data across devices

**Use Cases**:
- Sync reading progress
- Sync bookmarks and highlights
- Sync preferences

**Configuration**:

1. **In Xcode**:
   - Add "iCloud" capability
   - Enable "CloudKit"
   - Select or create container

2. **Implementation**:
   - Use CloudKit APIs or third-party package
   - Handle sync conflicts
   - Respect user's iCloud settings

## Capability Testing

### Testing Background Modes

1. **Audio Background Mode**:
   - Start audiobook playback
   - Press home button
   - Verify audio continues playing
   - Test control center controls

2. **Background Fetch**:
   - Enable in Settings → Developer → Background Fetch
   - Trigger background fetch in Xcode: Debug → Simulate Background Fetch
   - Verify content updates

3. **Remote Notifications**:
   - Send test notification from backend
   - Verify notification appears when app is backgrounded
   - Test notification tap handling

### Testing Push Notifications

1. **Development**:
   - Use APNs development certificate
   - Send test notification using tool like Pusher
   - Verify notification delivery

2. **Production**:
   - Use APNs production certificate
   - Test with TestFlight build
   - Verify notification delivery in production environment

### Testing Permissions

1. **Photo Library**:
   - Attempt to select photo
   - Verify permission prompt appears
   - Test both allow and deny scenarios

2. **Camera**:
   - Attempt to take photo
   - Verify permission prompt appears
   - Test both allow and deny scenarios

## Troubleshooting

### Background Modes Not Working

**Issue**: Audio stops when app is backgrounded

**Solutions**:
1. Verify "Audio, AirPlay, and Picture in Picture" is enabled
2. Check audio session is configured correctly:
   ```swift
   try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
   try AVAudioSession.sharedInstance().setActive(true)
   ```
3. Ensure app is playing audio before backgrounding

### Push Notifications Not Received

**Issue**: Notifications not appearing

**Solutions**:
1. Verify Push Notifications capability is enabled
2. Check APNs certificate is valid and not expired
3. Verify device token is registered with backend
4. Check notification payload format
5. Ensure app has notification permission
6. Test with different notification priorities

### Permission Prompts Not Appearing

**Issue**: Permission dialog doesn't show

**Solutions**:
1. Verify usage description is in Info.plist
2. Check permission hasn't been previously denied
3. Reset permissions: Settings → General → Reset → Reset Location & Privacy
4. Ensure requesting permission at appropriate time

### Universal Links Not Working

**Issue**: Links open in Safari instead of app

**Solutions**:
1. Verify Associated Domains capability is configured
2. Check apple-app-site-association file is accessible
3. Verify file is served with correct content-type: `application/json`
4. Test with different link formats
5. Check App ID has Associated Domains enabled

## Security Considerations

### 1. Minimize Permissions

- Only request permissions that are absolutely necessary
- Request permissions at the point of use, not on app launch
- Provide clear explanations for why permissions are needed

### 2. Handle Permission Denial

- Gracefully handle when user denies permission
- Provide alternative flows when possible
- Don't repeatedly prompt for denied permissions

### 3. Secure Data Storage

- Use Keychain for sensitive data (tokens, passwords)
- Encrypt downloaded content
- Respect user's privacy settings

### 4. Network Security

- Use HTTPS for all network requests
- Implement certificate pinning for critical endpoints
- Validate SSL certificates

## Compliance

### App Store Review Guidelines

Ensure capabilities comply with:
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Privacy requirements
- Data collection policies

### Privacy Policy

Update privacy policy to reflect:
- What data is collected
- How data is used
- What permissions are required
- User's rights regarding their data

### Data Collection Disclosure

In App Store Connect, declare:
- Data types collected
- Purpose of data collection
- Whether data is linked to user identity
- Whether data is used for tracking

## References

- [Apple Capabilities Documentation](https://developer.apple.com/documentation/xcode/capabilities)
- [Background Execution](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)
- [Push Notifications](https://developer.apple.com/documentation/usernotifications)
- [App Transport Security](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)
- [Universal Links](https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content)

## Checklist

Before submitting to App Store:

- [ ] All required capabilities are enabled in Xcode
- [ ] All required capabilities are enabled in App ID
- [ ] Usage descriptions are added to Info.plist
- [ ] Permissions are requested at appropriate times
- [ ] Permission denial is handled gracefully
- [ ] Background modes are tested and working
- [ ] Push notifications are tested and working
- [ ] Privacy policy is updated
- [ ] Data collection is disclosed in App Store Connect
- [ ] App complies with App Store Review Guidelines

