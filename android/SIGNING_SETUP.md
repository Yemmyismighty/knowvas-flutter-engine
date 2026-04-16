# Android Signing Configuration

This document explains how to configure Android app signing for the Knowvas Flutter client.

## Overview

The app supports multiple build variants and signing configurations:
- **Debug**: Uses debug keystore for development
- **Release**: Uses production keystore for Play Store releases
- **Profile**: Uses release keystore with profiling enabled

## Build Variants

### Build Types
- `debug`: Development builds with debugging enabled
- `release`: Production builds with code shrinking and obfuscation
- `profile`: Performance profiling builds

### Product Flavors
- `production`: Production environment (api.knowvas.com)
- `staging`: Staging environment (staging-api.knowvas.com)
- `development`: Development environment (dev-api.knowvas.com)

### Combined Variants
Examples: `productionDebug`, `stagingRelease`, `developmentDebug`

## Local Development Setup

### Step 1: Generate a Keystore

For local testing of release builds, generate a keystore:

```bash
keytool -genkey -v -keystore ~/knowvas-release.keystore -alias knowvas -keyalg RSA -keysize 2048 -validity 10000
```

### Step 2: Create key.properties File

Create `android/key.properties` with your keystore details:

```properties
storeFile=/path/to/your/knowvas-release.keystore
storePassword=your_store_password
keyAlias=knowvas
keyPassword=your_key_password
```

**Important**: Never commit `key.properties` to version control!


### Step 3: Add to .gitignore

Ensure these files are in your `.gitignore`:

```
android/key.properties
android/*.keystore
android/*.jks
```

## CI/CD Setup (GitHub Actions, etc.)

For automated builds, use environment variables instead of `key.properties`:

### Required Environment Variables

```bash
KEYSTORE_FILE=/path/to/keystore.jks
KEYSTORE_PASSWORD=your_store_password
KEY_ALIAS=your_key_alias
KEY_PASSWORD=your_key_password
VERSION_CODE=1
VERSION_NAME=1.0.0
```

### Example GitHub Actions Workflow

```yaml
- name: Build Release APK
  env:
    KEYSTORE_FILE: ${{ secrets.KEYSTORE_FILE }}
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
    VERSION_CODE: ${{ github.run_number }}
    VERSION_NAME: "1.0.${{ github.run_number }}"
  run: |
    cd knowvas_flutter_client
    flutter build apk --release --flavor production
```

### Storing Keystore in CI

1. Encode keystore to base64:
   ```bash
   base64 -i knowvas-release.keystore -o keystore.base64
   ```

2. Add as GitHub secret: `KEYSTORE_BASE64`

3. Decode in workflow:
   ```yaml
   - name: Decode keystore
     run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore
   ```


## Building Different Variants

### Debug Builds

```bash
# Production debug
flutter build apk --debug --flavor production

# Staging debug
flutter build apk --debug --flavor staging

# Development debug
flutter build apk --debug --flavor development
```

### Release Builds

```bash
# Production release (for Play Store)
flutter build appbundle --release --flavor production

# Staging release
flutter build apk --release --flavor staging

# Development release
flutter build apk --release --flavor development
```

### Profile Builds

```bash
flutter build apk --profile --flavor production
```

## ProGuard Configuration

The app uses ProGuard for code shrinking and obfuscation in release builds.

### ProGuard Rules Location
`android/app/proguard-rules.pro`

### Key Rules
- Keeps Flutter framework classes
- Preserves native reader plugin classes
- Protects Readium SDK
- Maintains Kotlin coroutines
- Removes debug logging in release

### Testing ProGuard

Always test release builds thoroughly as ProGuard can break functionality:

```bash
flutter build apk --release --flavor production
flutter install
```

## Version Management

### Automatic Versioning

Version code and name can be set via environment variables:

```bash
export VERSION_CODE=42
export VERSION_NAME="1.2.3"
flutter build appbundle --release --flavor production
```

### Manual Versioning

Edit `pubspec.yaml`:

```yaml
version: 1.2.3+42
```

Where `1.2.3` is the version name and `42` is the version code.


## Build Configuration Fields

The app includes build-specific configuration accessible in Kotlin code:

```kotlin
import com.knowvas.knowvas_flutter_client.BuildConfig

// API base URL (different per flavor)
val apiUrl = BuildConfig.API_BASE_URL

// Logging flag (false in release)
if (BuildConfig.ENABLE_LOGGING) {
    Log.d("TAG", "Debug message")
}

// Build type
val isDebug = BuildConfig.DEBUG
```

## Troubleshooting

### Issue: "Keystore file not found"

**Solution**: Ensure `key.properties` exists and `storeFile` path is correct.

### Issue: "Wrong password" during signing

**Solution**: Verify passwords in `key.properties` or environment variables.

### Issue: App crashes in release but works in debug

**Solution**: Check ProGuard rules. Add keep rules for classes being stripped.

### Issue: Different API URLs not working

**Solution**: Verify flavor is specified in build command: `--flavor production`

## Security Best Practices

1. **Never commit keystores or passwords** to version control
2. **Use different keystores** for debug and release
3. **Rotate keystores** if compromised
4. **Limit access** to production keystore
5. **Use Play App Signing** for additional security
6. **Enable certificate pinning** in production (optional)

## Play Store Release Checklist

- [ ] Generate production keystore
- [ ] Configure `key.properties` or CI environment variables
- [ ] Test release build thoroughly
- [ ] Verify ProGuard doesn't break functionality
- [ ] Check app size after shrinking
- [ ] Test on multiple devices and Android versions
- [ ] Build App Bundle: `flutter build appbundle --release --flavor production`
- [ ] Upload to Play Console
- [ ] Enable Play App Signing (recommended)

## Additional Resources

- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)
- [ProGuard Documentation](https://www.guardsquare.com/manual/home)
