# Integration Tests - Quick Start Guide

## TL;DR

```bash
# Run all tests (Linux/Mac)
./integration_test/run_all_tests.sh

# Run all tests (Windows)
integration_test\run_all_tests.bat

# Run specific test
flutter test integration_test/e2e_complete_journey_test.dart
```

## Prerequisites

1. Flutter SDK installed
2. Device/emulator running
3. Dependencies installed: `flutter pub get`

## Test Files

| File | Purpose | Duration |
|------|---------|----------|
| `app_test.dart` | Basic app flows | ~1 min |
| `reader_integration_test.dart` | Reader functionality | ~1 min |
| `e2e_complete_journey_test.dart` | Complete user journey | ~2-3 min |
| `multi_device_test.dart` | Multi-device support | ~1-2 min |

## Common Commands

### Run All Tests
```bash
# Linux/Mac
chmod +x integration_test/run_all_tests.sh
./integration_test/run_all_tests.sh

# Windows
integration_test\run_all_tests.bat

# With specific device
./integration_test/run_all_tests.sh <device_id>
```

### Run Individual Tests
```bash
# Basic app tests
flutter test integration_test/app_test.dart

# Reader tests
flutter test integration_test/reader_integration_test.dart

# E2E journey
flutter test integration_test/e2e_complete_journey_test.dart

# Multi-device
flutter test integration_test/multi_device_test.dart
```

### Platform-Specific
```bash
# Android
flutter test integration_test/app_test.dart -d android

# iOS
flutter test integration_test/app_test.dart -d ios

# Specific device
flutter devices  # List devices
flutter test integration_test/app_test.dart -d <device_id>
```

### Run Specific Test
```bash
flutter test integration_test/app_test.dart --plain-name="Sign-in flow end-to-end"
```

## What Gets Tested

### ✅ Complete User Journey
- Sign-up → Browse → Purchase → Download → Read → Offline → Sync

### ✅ Offline Mode
- Downloaded content access
- Event queuing
- Sync after network restore

### ✅ Multi-Device Support
- Phone and tablet sizes
- Landscape orientation
- Platform-specific features (Android/iOS)
- Accessibility (text scale, reduced motion)

### ✅ Cross-Feature Integration
- Settings affecting reader
- Library to reader flow
- Download to offline to sync

## Troubleshooting

### Tests Timeout
```dart
// Increase timeout in test
await tester.pumpAndSettle(const Duration(seconds: 5));
```

### Widget Not Found
```bash
# Add debug output
debugDumpApp()
```

### Platform Channel Errors
- Ensure mocks are set up in `setUp()`
- Verify channel names match exactly

### Device Not Found
```bash
# List available devices
flutter devices

# Start emulator
flutter emulators --launch <emulator_id>
```

## Test Results

Tests verify:
- ✅ UI renders correctly
- ✅ Navigation works
- ✅ Data persists
- ✅ API calls made
- ✅ Offline mode functions
- ✅ Sync works
- ✅ Platform-specific features work

## Next Steps

1. Run tests locally
2. Fix any failures
3. Integrate into CI/CD
4. Run on physical devices
5. Add to release checklist

## Documentation

- **README.md** - Comprehensive documentation
- **E2E_TESTING_SUMMARY.md** - Implementation summary
- **TEST_EXECUTION_CHECKLIST.md** - Testing checklist

## Support

For detailed information, see:
- `integration_test/README.md` - Full documentation
- `integration_test/E2E_TESTING_SUMMARY.md` - Implementation details
- Test files themselves - Inline comments and examples
