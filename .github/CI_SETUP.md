# CI/CD Setup Guide

This guide explains how to set up and use the CI/CD pipeline for the Knowvas Flutter client.

## Quick Start

The CI pipeline is already configured and will run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

## Local Testing Before Push

Before pushing code, run these commands locally to catch issues early:

```bash
# Navigate to project directory
cd knowvas_flutter_client

# Format code
dart format .

# Analyze code
flutter analyze

# Run unit tests
flutter test

# Run integration tests (requires emulator/simulator)
flutter test integration_test
```

## CI Pipeline Overview

The pipeline consists of 5 jobs:

1. **Flutter Tests** - Lint, format, analyze, unit tests (runs first)
2. **Android Tests** - Integration tests on Android emulator (parallel)
3. **iOS Tests** - Integration tests on iOS simulator (parallel)
4. **Build Android** - Build APK and AAB (after Flutter tests pass)
5. **Build iOS** - Build iOS app (after Flutter tests pass)

## Viewing CI Results

1. Go to your repository on GitHub
2. Click the "Actions" tab
3. Click on a workflow run to see details
4. Click on individual jobs to see logs

## Downloading Build Artifacts

After a successful build:

1. Go to Actions → Select workflow run
2. Scroll to "Artifacts" section
3. Download:
   - `android-apk` - Android APK file
   - `android-aab` - Android App Bundle
   - `ios-build-info` - iOS build instructions

## Setting Up Code Coverage (Optional)

To enable code coverage reporting:

1. Sign up at https://codecov.io/
2. Add your repository
3. Get your Codecov token
4. Add it to GitHub:
   - Go to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `CODECOV_TOKEN`
   - Value: Your Codecov token
   - Click "Add secret"

## Troubleshooting

### "Format check failed"
```bash
# Fix formatting
dart format .
```

### "Analysis issues found"
```bash
# Check issues
flutter analyze

# Fix issues in code
```

### "Tests failed"
```bash
# Run tests locally to debug
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart

# Run with verbose output
flutter test --verbose
```

### "Android build failed"
```bash
# Check Android build locally
cd android
./gradlew build --stacktrace
```

### "iOS build failed"
```bash
# Check iOS build locally
flutter build ios --no-codesign
```

## Best Practices

1. **Always run tests locally** before pushing
2. **Keep tests fast** - CI runs on every push
3. **Fix CI failures immediately** - Don't let them accumulate
4. **Review CI logs** when tests fail
5. **Update dependencies regularly** to avoid security issues

## CI Configuration Files

- `.github/workflows/ci.yml` - Main CI workflow
- `.github/workflows/README.md` - Detailed workflow documentation
- `analysis_options.yaml` - Dart analyzer configuration
- `android/build.gradle` - Android build configuration
- `ios/Runner.xcodeproj` - iOS build configuration

## Adding New Tests

### Unit Tests
1. Create test file in `test/` directory
2. Name it `*_test.dart`
3. CI will automatically run it

### Integration Tests
1. Create test file in `integration_test/` directory
2. Name it `*_test.dart`
3. CI will run it on emulators/simulators

### Native Android Tests
1. Create test file in `android/app/src/test/`
2. Name it `*Test.kt`
3. CI will run it with Gradle

### Native iOS Tests
1. Create test file in `ios/RunnerTests/`
2. Name it `*Tests.swift`
3. CI will run it with xcodebuild

## Performance Tips

- **Use `--coverage` flag** only when needed (slower)
- **Mock external dependencies** in tests
- **Keep integration tests focused** - test critical paths only
- **Use test groups** to organize tests

## Getting Help

If you encounter issues with CI:

1. Check the workflow logs in GitHub Actions
2. Review this documentation
3. Check Flutter documentation: https://docs.flutter.dev/
4. Check GitHub Actions documentation: https://docs.github.com/actions

## Requirements Covered

This CI setup fulfills the following requirements:

- ✅ 17.1: Lint and format checks for Dart, Kotlin, and Swift
- ✅ 17.2: Unit tests on Linux for Flutter code
- ✅ 17.3: Android instrumented tests on emulator (API 29, 33)
- ✅ 17.4: iOS unit tests on macOS runner
- ✅ 17.5: Build Android APK and AAB artifacts
- ✅ 17.6: Build iOS XCArchive (with signing instructions)
- ✅ 17.7: Environment variables for secrets (documented)
- ✅ 17.8: Clear error messages and logs
- ✅ 17.9: Documentation in repository
