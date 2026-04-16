# GitHub Actions CI/CD Workflows

This directory contains the CI/CD workflows for the Knowvas Flutter client.

## Workflows

### CI Workflow (`ci.yml`)

The main CI workflow runs on every push and pull request to `main` and `develop` branches. It includes the following jobs:

#### 1. Flutter Tests (`flutter-test`)
- **Runs on**: Ubuntu latest
- **Purpose**: Lint, format check, analyze, and run unit tests
- **Steps**:
  - Checkout code
  - Set up Flutter (stable channel)
  - Get dependencies
  - Verify code formatting with `dart format`
  - Analyze code with `flutter analyze`
  - Run unit tests with coverage
  - Upload coverage to Codecov (requires `CODECOV_TOKEN` secret)

#### 2. Android Tests (`android-test`)
- **Runs on**: Ubuntu latest
- **Matrix**: API levels 29 and 33
- **Purpose**: Run integration tests on Android emulator
- **Steps**:
  - Checkout code
  - Set up JDK 17
  - Set up Flutter
  - Get dependencies
  - Enable KVM for hardware acceleration
  - Run integration tests on Android emulator
  - Run Android native unit tests (Kotlin tests)

#### 3. iOS Tests (`ios-test`)
- **Runs on**: macOS latest
- **Purpose**: Run integration tests on iOS simulator
- **Steps**:
  - Checkout code
  - Set up Flutter
  - Get dependencies
  - Start iOS Simulator (iPhone 15 Pro)
  - Run integration tests on simulator
  - Run iOS native unit tests (Swift tests)

#### 4. Build Android (`build-android`)
- **Runs on**: Ubuntu latest
- **Depends on**: `flutter-test`
- **Purpose**: Build Android APK and App Bundle
- **Steps**:
  - Checkout code
  - Set up JDK 17
  - Set up Flutter
  - Get dependencies
  - Build release APK
  - Build release App Bundle (AAB)
  - Upload APK as artifact (30-day retention)
  - Upload AAB as artifact (30-day retention)

#### 5. Build iOS (`build-ios`)
- **Runs on**: macOS latest
- **Depends on**: `flutter-test`
- **Purpose**: Build iOS app (without code signing)
- **Steps**:
  - Checkout code
  - Set up Flutter
  - Get dependencies
  - Build iOS release (no codesign)
  - Create build info file with signing instructions
  - Upload build info as artifact

## Configuration

### Required Secrets

To enable all features, configure the following secrets in your GitHub repository:

1. **CODECOV_TOKEN** (Optional)
   - For uploading test coverage to Codecov
   - Get from: https://codecov.io/
   - Path: Settings → Secrets and variables → Actions → New repository secret

### Android Signing (Future Enhancement)

For signed Android builds, you'll need to add:
- `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_ALIAS`: Key alias
- `ANDROID_KEY_PASSWORD`: Key password

### iOS Signing (Future Enhancement)

For signed iOS builds, you'll need to:
- Set up certificates and provisioning profiles in Xcode
- Configure signing in the iOS project
- Use `flutter build ipa` instead of `flutter build ios --no-codesign`
- Add signing certificates and profiles as secrets

## Running Workflows

### Automatic Triggers
- **Push**: Workflows run automatically on push to `main` or `develop`
- **Pull Request**: Workflows run on PRs targeting `main` or `develop`

### Manual Trigger
You can manually trigger the CI workflow:
1. Go to Actions tab in GitHub
2. Select "CI" workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## Artifacts

Build artifacts are available for 30 days after the workflow run:

- **android-apk**: Release APK file
- **android-aab**: Release App Bundle file
- **ios-build-info**: iOS build information and signing instructions

To download artifacts:
1. Go to Actions tab
2. Click on a workflow run
3. Scroll to "Artifacts" section
4. Click on artifact name to download

## Troubleshooting

### Flutter Tests Failing
- Check formatting: `dart format .`
- Check analysis: `flutter analyze`
- Run tests locally: `flutter test`

### Android Tests Failing
- Ensure Android SDK is properly configured
- Check Gradle build: `cd android && ./gradlew build`
- Run tests locally: `flutter test integration_test`

### iOS Tests Failing
- Ensure Xcode is properly configured
- Check iOS build: `flutter build ios --no-codesign`
- Run tests locally on simulator

### Build Artifacts Not Generated
- Check if `flutter-test` job passed (builds depend on it)
- Review build logs for errors
- Ensure Flutter version is compatible

## Performance Optimization

The workflow includes several optimizations:
- **Caching**: Flutter SDK and dependencies are cached
- **Parallel Jobs**: Tests run in parallel where possible
- **Matrix Strategy**: Android tests run on multiple API levels simultaneously
- **Fail-Fast**: Disabled for Android matrix to test all API levels even if one fails

## Future Enhancements

- Add code signing for production releases
- Implement automatic deployment to Play Store and App Store
- Add performance benchmarking
- Integrate additional code quality tools (SonarQube, etc.)
- Add security scanning (SAST/DAST)
- Implement release automation with semantic versioning
