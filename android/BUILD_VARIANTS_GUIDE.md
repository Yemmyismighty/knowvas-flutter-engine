# Android Build Variants Quick Reference

## Available Build Variants

The Knowvas Flutter client supports multiple build configurations:

### Build Types
| Type | Description | Debuggable | Minified | Signing |
|------|-------------|------------|----------|---------|
| debug | Development builds | Yes | No | Debug keystore |
| release | Production builds | No | Yes | Release keystore |
| profile | Performance profiling | No | No | Release keystore |

### Product Flavors
| Flavor | API URL | App ID Suffix | Use Case |
|--------|---------|---------------|----------|
| production | api.knowvas.com | - | Play Store release |
| staging | staging-api.knowvas.com | .staging | Pre-release testing |
| development | dev-api.knowvas.com | .dev | Development testing |

## Quick Build Commands

### Development
```bash
# Run on device/emulator
flutter run --flavor development

# Build APK
flutter build apk --debug --flavor development
```

### Staging Testing
```bash
# Build release APK for staging
flutter build apk --release --flavor staging

# Install on device
flutter install --release --flavor staging
```

### Production Release
```bash
# Build App Bundle for Play Store
flutter build appbundle --release --flavor production

# Build APK for direct distribution
flutter build apk --release --flavor production
```

## Build Outputs

APKs are generated in:
```
build/app/outputs/flutter-apk/
```

App Bundles are generated in:
```
build/app/outputs/bundle/
```

## Variant-Specific Features

### Debug Builds
- Logging enabled
- Debug API endpoints
- Hot reload support
- Larger app size

### Release Builds
- Code obfuscation (ProGuard)
- Resource shrinking
- Optimized performance
- Smaller app size
- Logging disabled

### Profile Builds
- Performance profiling enabled
- Similar to release but with profiling tools
- Used for performance testing

## Environment-Specific Configuration

Each flavor has its own API base URL configured in `build.gradle`:

```kotlin
// Access in Kotlin code
val apiUrl = BuildConfig.API_BASE_URL
```

## Version Management

Set version via environment variables:
```bash
export VERSION_CODE=42
export VERSION_NAME="1.2.3"
flutter build appbundle --release --flavor production
```

Or edit `pubspec.yaml`:
```yaml
version: 1.2.3+42
```

## Common Issues

**Q: Build fails with "Keystore not found"**
A: Create `android/key.properties` or use debug signing. See SIGNING_SETUP.md

**Q: Different flavors show same API URL**
A: Ensure you're specifying `--flavor` in build command

**Q: Release build crashes but debug works**
A: Check ProGuard rules in `proguard-rules.pro`

## See Also

- [SIGNING_SETUP.md](./SIGNING_SETUP.md) - Detailed signing configuration
- [proguard-rules.pro](./app/proguard-rules.pro) - ProGuard configuration
