# Integration Tests

This directory contains comprehensive integration tests for the Knowvas Flutter client app.

## Overview

The integration tests verify end-to-end functionality of the app across multiple scenarios:

### Test Files

1. **app_test.dart** - Basic app integration tests
   - Sign-in flow
   - Library browsing
   - Reader launch with mocked platform channels
   - Reader event reception

2. **reader_integration_test.dart** - Reader-specific integration tests
   - Platform channel communication
   - Reader event stream handling
   - Reader state management
   - Multiple event processing

3. **e2e_complete_journey_test.dart** - Complete user journey tests
   - Sign-up → Browse → Purchase → Download → Read → Offline → Sync
   - Offline mode with downloaded content access
   - Sync after network restore
   - Cross-feature integration (settings affecting reader)

4. **multi_device_test.dart** - Multi-device and OS version tests
   - Phone and tablet screen sizes
   - Landscape orientation
   - Platform-specific features (Android/iOS)
   - Accessibility (text scale, reduced motion)
   - Network switching
   - Low memory conditions

## Running Integration Tests

### Prerequisites

- Flutter SDK installed and configured
- Android emulator or iOS simulator running (or physical device connected)
- App dependencies installed (`flutter pub get`)

### Quick Start

Run all tests using the provided scripts:

**Linux/Mac:**
```bash
chmod +x integration_test/run_all_tests.sh
./integration_test/run_all_tests.sh
```

**Windows:**
```cmd
integration_test\run_all_tests.bat
```

**With specific device:**
```bash
# Linux/Mac
./integration_test/run_all_tests.sh <device_id>

# Windows
integration_test\run_all_tests.bat <device_id>
```

### Run Individual Test Files

```bash
# Basic app tests
flutter test integration_test/app_test.dart

# Reader tests
flutter test integration_test/reader_integration_test.dart

# Complete E2E journey
flutter test integration_test/e2e_complete_journey_test.dart

# Multi-device tests
flutter test integration_test/multi_device_test.dart
```

### Run on Specific Platform

```bash
# Android
flutter test integration_test/app_test.dart -d android

# iOS
flutter test integration_test/app_test.dart -d ios

# Chrome (for web testing)
flutter test integration_test/app_test.dart -d chrome

# Specific device
flutter test integration_test/app_test.dart -d <device_id>
```

### Run Specific Test

```bash
flutter test integration_test/app_test.dart --plain-name="Sign-in flow end-to-end"
```

### List Available Devices

```bash
flutter devices
```

## Test Coverage

### Complete User Journey (e2e_complete_journey_test.dart)

✅ **Phase 1: Sign-up**
- New user registration
- Form validation
- Account creation

✅ **Phase 2: Browse and Discover**
- Content discovery
- Search and filtering
- Content details

✅ **Phase 3: Purchase**
- Add to cart
- Checkout process
- Payment handling

✅ **Phase 4: Library Access**
- View purchased content
- Library organization
- Content metadata

✅ **Phase 5: Download**
- Content download
- Progress tracking
- File encryption

✅ **Phase 6: Reading**
- Reader launch
- Page navigation
- Bookmarks and highlights

✅ **Phase 7: Offline Mode**
- Network disconnection
- Offline reading
- Event queuing

✅ **Phase 8: Offline Library**
- Downloaded content access
- Offline filtering

✅ **Phase 9: Sync**
- Network restoration
- Event upload
- Data synchronization

✅ **Phase 10: Profile and Stats**
- Reading statistics
- User profile
- Achievements

### Multi-Device Support (multi_device_test.dart)

✅ **Screen Sizes**
- Phone (375x667)
- Tablet (1024x768)
- Landscape orientation

✅ **Platform-Specific**
- Android Material Design
- iOS Cupertino widgets
- Platform navigation patterns

✅ **Accessibility**
- Large text scale (2.0x)
- Reduced motion
- Screen reader support

✅ **System Integration**
- Theme changes
- Network switching
- Low memory handling

## Mocking Strategy

### Platform Channels

The tests use comprehensive mocking for platform channels:

**Reader Method Channel** (`com.knowvas.reader/channel`):
- `openReader` - Returns success response
- `closeReader` - Handles reader cleanup
- `setReaderPrefs` - Applies reader settings

**Reader Event Channel** (`com.knowvas.reader/events`):
- `ready` - Reader initialization complete
- `engagement` - Page turns, bookmarks, highlights
- `error` - Error handling

**Connectivity Channel** (`dev.fluttercommunity.plus/connectivity`):
- `check` - Returns network status (wifi/cellular/none)
- Simulates online/offline transitions

### Network Simulation

Tests can simulate:
- Online state (WiFi/cellular)
- Offline state
- Network transitions
- API call tracking

## Test Execution Flow

```
1. Setup
   ├── Initialize test binding
   ├── Setup mock channels
   └── Configure test environment

2. Test Execution
   ├── Launch app
   ├── Perform user actions
   ├── Verify UI state
   ├── Check API calls
   └── Validate behavior

3. Teardown
   ├── Close streams
   ├── Reset mocks
   └── Clean up resources
```

## Best Practices

### Writing Integration Tests

1. **Use descriptive test names**
   ```dart
   testWidgets('Complete journey: Sign-up → Browse → Purchase → Download → Read',
       (WidgetTester tester) async { ... });
   ```

2. **Handle async operations properly**
   ```dart
   await tester.pumpAndSettle(const Duration(seconds: 2));
   ```

3. **Make tests resilient**
   ```dart
   if (signInButton.evaluate().isNotEmpty) {
     await tester.tap(signInButton.first);
   }
   ```

4. **Verify multiple conditions**
   ```dart
   final hasContent = find.byType(GridView).evaluate().isNotEmpty ||
       find.byType(ListView).evaluate().isNotEmpty;
   expect(hasContent, isTrue);
   ```

5. **Clean up resources**
   ```dart
   tearDown(() {
     readerEventController.close();
   });
   ```

## Troubleshooting

### Tests Timeout

**Problem:** Tests hang or timeout

**Solutions:**
- Increase timeout duration: `await tester.pumpAndSettle(const Duration(seconds: 5));`
- Check for infinite animations
- Verify async operations complete
- Use `pump()` instead of `pumpAndSettle()` for specific timing

### Platform Channel Errors

**Problem:** `MissingPluginException` or channel errors

**Solutions:**
- Ensure mock setup is called in `setUp()`
- Verify channel names match exactly
- Check response format matches app expectations
- Use `TestDefaultBinaryMessengerBinding.instance`

### Widget Not Found

**Problem:** `find.text()` or `find.byType()` returns empty

**Solutions:**
- Add debug print: `debugDumpApp()` or `debugPrint(tester.allWidgets.toString())`
- Use more flexible finders: `find.byType()` instead of `find.text()`
- Check if app is in expected state
- Verify navigation completed: `await tester.pumpAndSettle()`

### State Issues

**Problem:** App is in unexpected state

**Solutions:**
- Add helper functions for common flows (sign-in, navigation)
- Check for existing state before actions
- Reset app state between tests if needed
- Use `setUp()` and `tearDown()` properly

### Device-Specific Issues

**Problem:** Tests pass on one device but fail on another

**Solutions:**
- Test on multiple devices/emulators
- Use adaptive layouts
- Handle platform differences explicitly
- Test different screen sizes

## Performance Considerations

### Test Execution Time

- Basic tests: ~30-60 seconds
- Complete E2E journey: ~2-3 minutes
- Multi-device tests: ~1-2 minutes
- Full suite: ~5-10 minutes

### Optimization Tips

1. **Run tests in parallel** (when possible)
2. **Use mocks** instead of real backend
3. **Skip unnecessary animations**
4. **Reuse app state** between related tests
5. **Profile slow tests** and optimize

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test integration_test/
```

### Test Reports

Generate test reports:
```bash
flutter test integration_test/ --reporter json > test_results.json
```

## Future Improvements

- [ ] Add visual regression testing with screenshots
- [ ] Implement performance benchmarking
- [ ] Add code coverage reporting
- [ ] Test deep linking scenarios
- [ ] Add automated accessibility audits
- [ ] Test with real backend (staging environment)
- [ ] Add load testing for concurrent users
- [ ] Implement golden file testing for UI consistency

## Notes

- Tests are designed to be resilient to backend unavailability
- Mocks simulate successful responses; error cases tested separately
- Tests handle various app states (signed in, signed out, etc.)
- Platform channel mocks prevent errors when native modules unavailable
- Tests verify both happy path and edge cases

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review test implementation for examples
3. Check Flutter integration testing docs
4. Review app architecture documentation
