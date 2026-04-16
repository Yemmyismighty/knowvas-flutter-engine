# Android Native Tests

This directory contains instrumented tests for the native Android reader modules (EPUB, PDF, and Comic readers).

## Test Coverage

### EpubReaderTest
Tests for the EPUB reader module including:
- Reader initialization
- Opening EPUB files (valid and invalid)
- Page navigation
- Settings and preferences
- Audio playback controls
- Memory management
- Cache statistics
- Error handling

### PdfReaderTest
Tests for the PDF reader module including:
- Reader initialization
- Opening PDF files (valid and invalid)
- Page navigation (next, previous, go to page)
- Rendering pages
- Zoom functionality
- Bookmark operations
- Settings and preferences
- Error handling

### ComicReaderTest
Tests for the Comic reader module including:
- Reader initialization
- Opening comic archives (CBZ, CBR)
- Page navigation
- Image loading and caching
- Layout modes (single page, double page)
- Reading direction (LTR, RTL)
- Guided view
- Memory management
- Error handling

## Requirements

These tests satisfy **Requirement 16.5**:
- Test EPUB opening and page navigation
- Test PDF rendering and zoom
- Test comic image loading

## Running the Tests

### From Android Studio
1. Open the project in Android Studio
2. Navigate to `android/app/src/androidTest/kotlin/com/knowvas/reader/`
3. Right-click on a test file or test method
4. Select "Run [TestName]"

### From Command Line

#### Run all instrumented tests:
```bash
cd knowvas_flutter_client/android
./gradlew connectedAndroidTest
```

#### Run specific test class:
```bash
./gradlew connectedAndroidTest --tests "com.knowvas.reader.epub.EpubReaderTest"
./gradlew connectedAndroidTest --tests "com.knowvas.reader.pdf.PdfReaderTest"
./gradlew connectedAndroidTest --tests "com.knowvas.reader.comic.ComicReaderTest"
```

#### Run specific test method:
```bash
./gradlew connectedAndroidTest --tests "com.knowvas.reader.epub.EpubReaderTest.testEpubReaderInitialization"
```

### From Flutter Project Root
```bash
cd knowvas_flutter_client
flutter test integration_test/
```

## Prerequisites

1. **Android Device or Emulator**: Tests must run on a physical device or emulator
   - Minimum API level: 24 (Android 7.0)
   - Recommended: API level 30+ for best compatibility

2. **Enable USB Debugging** (for physical devices):
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times to enable Developer Options
   - Go to Settings > Developer Options
   - Enable "USB Debugging"

3. **Connect Device**:
   ```bash
   adb devices
   ```
   Should show your device listed

## Test Structure

Each test file follows this structure:

```kotlin
@RunWith(AndroidJUnit4::class)
class ReaderTest {
    private lateinit var context: Context
    private lateinit var reader: Reader
    private val mockEventSink: EventChannel.EventSink
    
    @Before
    fun setup() {
        // Initialize test environment
    }
    
    @After
    fun tearDown() {
        // Clean up resources
    }
    
    @Test
    fun testSomething() {
        // Test implementation
    }
}
```

## Test Categories

### Unit Tests (without device)
Located in `android/app/src/test/kotlin/`
- Run with: `./gradlew test`

### Instrumented Tests (with device)
Located in `android/app/src/androidTest/kotlin/`
- Run with: `./gradlew connectedAndroidTest`
- Require a connected device or emulator

## Viewing Test Results

### Command Line
Test results are generated in:
```
android/app/build/reports/androidTests/connected/index.html
```

Open this file in a browser to view detailed test results.

### Android Studio
- Test results appear in the "Run" panel at the bottom
- Click on individual tests to see details
- Failed tests show stack traces and error messages

## Continuous Integration

These tests are designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Android Tests
  run: |
    cd knowvas_flutter_client/android
    ./gradlew connectedAndroidTest
```

## Troubleshooting

### Tests fail with "No connected devices"
- Ensure a device or emulator is running
- Check with `adb devices`
- Start an emulator if needed

### Tests timeout
- Increase timeout in test configuration
- Check device performance
- Ensure device has sufficient storage

### Build errors
- Clean the project: `./gradlew clean`
- Sync Gradle files in Android Studio
- Check that all dependencies are downloaded

### Permission errors
- Ensure the app has necessary permissions
- Check AndroidManifest.xml for test permissions

## Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Always clean up resources in `@After`
3. **Mocking**: Use mock objects for external dependencies
4. **Assertions**: Use clear, descriptive assertion messages
5. **Coverage**: Aim for comprehensive test coverage of critical paths

## Adding New Tests

To add new tests:

1. Create a new test file in the appropriate package
2. Extend the test class with `@RunWith(AndroidJUnit4::class)`
3. Add `@Before` and `@After` methods for setup/cleanup
4. Write test methods with `@Test` annotation
5. Use descriptive test names: `testFeatureUnderSpecificCondition`
6. Add assertions to verify expected behavior

## Notes

- These tests focus on the reader modules' public APIs
- Tests verify error handling and edge cases
- Memory management and performance are tested where applicable
- Tests are designed to run quickly (< 5 seconds each)
- Some tests may require actual EPUB/PDF/Comic files for full integration testing
