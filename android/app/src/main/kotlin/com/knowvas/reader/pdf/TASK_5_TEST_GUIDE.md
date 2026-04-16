# Task 5: Test Execution Guide

## Quick Start

This guide shows you how to run the tests for Task 5 (Integration Checkpoint).

---

## Prerequisites

### For Unit Tests
- Java Development Kit (JDK) 17 or higher
- Android SDK
- Gradle (included in project)

### For Instrumented Tests
- All of the above, plus:
- Android device or emulator
- USB debugging enabled (for physical device)

---

## Running Unit Tests

Unit tests run on your development machine without requiring a device.

### Command Line

```bash
# Navigate to Android directory
cd knowvas_flutter_client/android

# Run all Task 5 unit tests
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest"

# Run a specific test
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest.testFlatMeshHasZeroDepth"

# Run with detailed output
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest" --info
```

### Android Studio

1. Open the project in Android Studio
2. Navigate to: `app/src/test/kotlin/com/knowvas/reader/pdf/Task5IntegrationCheckpointTest.kt`
3. Right-click on the file or a specific test
4. Select "Run 'Task5IntegrationCheckpointTest'"

### Expected Output

```
Task5IntegrationCheckpointTest > testFlatMeshHasZeroDepth PASSED
Task5IntegrationCheckpointTest > testMeshHasCorrectGridDimensions PASSED
Task5IntegrationCheckpointTest > testMeshHasCorrectTriangleCount PASSED
Task5IntegrationCheckpointTest > testTextureCoordinatesInValidRange PASSED
Task5IntegrationCheckpointTest > testVertexPositionsInValidRange PASSED
Task5IntegrationCheckpointTest > testTriangleWindingOrderIsConsistent PASSED
Task5IntegrationCheckpointTest > testMeshBuffersCanBeCreated PASSED
Task5IntegrationCheckpointTest > testMeshCornersAreAtExpectedPositions PASSED
Task5IntegrationCheckpointTest > testMeshTextureCornersAreAtExpectedPositions PASSED
Task5IntegrationCheckpointTest > testMeshCanBeGeneratedMultipleTimes PASSED
Task5IntegrationCheckpointTest > testMeshGenerationPerformance PASSED
Task5IntegrationCheckpointTest > testMeshDoesNotLeakMemory PASSED

BUILD SUCCESSFUL
12 tests, 12 passed
```

---

## Running Instrumented Tests

Instrumented tests run on an Android device or emulator and test OpenGL rendering.

### Setup Device/Emulator

#### Option 1: Physical Device
1. Enable Developer Options on your device
2. Enable USB Debugging
3. Connect device via USB
4. Verify connection: `adb devices`

#### Option 2: Emulator
1. Open Android Studio
2. Tools → Device Manager
3. Create or start an emulator
4. Wait for emulator to fully boot

### Command Line

```bash
# Navigate to Android directory
cd knowvas_flutter_client/android

# Run all instrumented tests
./gradlew connectedAndroidTest --tests "com.knowvas.reader.pdf.PageCurlIntegrationTest"

# Run a specific test
./gradlew connectedAndroidTest --tests "com.knowvas.reader.pdf.PageCurlIntegrationTest.testPageCurlViewDisplaysPdfPageCorrectly"

# Run with detailed output
./gradlew connectedAndroidTest --tests "com.knowvas.reader.pdf.PageCurlIntegrationTest" --info
```

### Android Studio

1. Open the project in Android Studio
2. Navigate to: `app/src/androidTest/kotlin/com/knowvas/reader/pdf/PageCurlIntegrationTest.kt`
3. Ensure a device/emulator is connected
4. Right-click on the file or a specific test
5. Select "Run 'PageCurlIntegrationTest'"

### Expected Output

```
PageCurlIntegrationTest > testPageCurlViewDisplaysPdfPageCorrectly PASSED
PageCurlIntegrationTest > testFlatMeshRendersIdenticallyToSimpleQuad PASSED
PageCurlIntegrationTest > testPerformanceTargets PASSED
PageCurlIntegrationTest > testNoMemoryLeaks PASSED
PageCurlIntegrationTest > testOpenGLInitialization PASSED
PageCurlIntegrationTest > testMeshGeneration PASSED
PageCurlIntegrationTest > testTextureCoordinatesInValidRange PASSED
PageCurlIntegrationTest > testVertexPositionsInValidRange PASSED

BUILD SUCCESSFUL
8 tests, 8 passed
```

---

## Test Files

### Unit Tests
**File**: `app/src/test/kotlin/com/knowvas/reader/pdf/Task5IntegrationCheckpointTest.kt`

**Tests** (12):
1. `testFlatMeshHasZeroDepth`
2. `testMeshHasCorrectGridDimensions`
3. `testMeshHasCorrectTriangleCount`
4. `testTextureCoordinatesInValidRange`
5. `testVertexPositionsInValidRange`
6. `testTriangleWindingOrderIsConsistent`
7. `testMeshBuffersCanBeCreated`
8. `testMeshCornersAreAtExpectedPositions`
9. `testMeshTextureCornersAreAtExpectedPositions`
10. `testMeshCanBeGeneratedMultipleTimes`
11. `testMeshGenerationPerformance`
12. `testMeshDoesNotLeakMemory`

### Instrumented Tests
**File**: `app/src/androidTest/kotlin/com/knowvas/reader/pdf/PageCurlIntegrationTest.kt`

**Tests** (8):
1. `testPageCurlViewDisplaysPdfPageCorrectly`
2. `testFlatMeshRendersIdenticallyToSimpleQuad`
3. `testPerformanceTargets`
4. `testNoMemoryLeaks`
5. `testOpenGLInitialization`
6. `testMeshGeneration`
7. `testTextureCoordinatesInValidRange`
8. `testVertexPositionsInValidRange`

---

## Troubleshooting

### Unit Tests

#### Problem: "JAVA_HOME is not set"
**Solution**:
```bash
# Windows
set JAVA_HOME=C:\Program Files\Java\jdk-17

# macOS/Linux
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
```

#### Problem: "Task 'test' not found"
**Solution**: Make sure you're in the `android` directory:
```bash
cd knowvas_flutter_client/android
```

#### Problem: Tests fail to compile
**Solution**: Clean and rebuild:
```bash
./gradlew clean
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest"
```

### Instrumented Tests

#### Problem: "No connected devices"
**Solution**: 
1. Check device connection: `adb devices`
2. Start an emulator if needed
3. Enable USB debugging on physical device

#### Problem: "Installation failed"
**Solution**:
```bash
# Uninstall old version
adb uninstall com.knowvas.knowvas_flutter_client.debug

# Try again
./gradlew connectedAndroidTest
```

#### Problem: Tests timeout
**Solution**: Increase timeout in `build.gradle`:
```gradle
android {
    defaultConfig {
        testInstrumentationRunnerArguments timeout: '300000' // 5 minutes
    }
}
```

#### Problem: OpenGL errors on emulator
**Solution**: 
1. Use a physical device (better OpenGL support)
2. Or create an emulator with:
   - Graphics: Hardware - GLES 2.0
   - API Level: 24 or higher

---

## Viewing Test Reports

### HTML Reports

After running tests, view detailed HTML reports:

#### Unit Tests
```bash
# Open in browser
open android/app/build/reports/tests/testDebugUnitTest/index.html

# Or navigate to:
# android/app/build/reports/tests/testDebugUnitTest/index.html
```

#### Instrumented Tests
```bash
# Open in browser
open android/app/build/reports/androidTests/connected/index.html

# Or navigate to:
# android/app/build/reports/androidTests/connected/index.html
```

### Console Output

For detailed console output, add `--info` or `--debug`:

```bash
# Detailed output
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest" --info

# Very detailed output
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest" --debug
```

---

## Performance Testing

### Measuring Performance

The performance tests measure:
- Mesh generation time (target: <10ms)
- Frame render time (target: <33ms for 30 FPS)
- Memory usage (target: <100MB GPU memory)

### Viewing Performance Metrics

Performance metrics are logged to console:

```
Mesh generation performance: 5.2ms average (100 iterations)
✓ Performance test passed: 5.2ms per mesh (target: <10ms)

Average frame time: 28.5ms
Average FPS: 35
✓ Performance test passed: 35 FPS (target: 30+ FPS)

Memory increase after 1000 mesh generations: 2.3MB
✓ Memory test passed: 2.3MB increase (threshold: 10MB)
```

### Profiling with Android Studio

For detailed profiling:

1. Open Android Studio
2. Run → Profile 'app'
3. Select device/emulator
4. Choose profiler:
   - CPU Profiler: For frame timing
   - Memory Profiler: For memory leaks
   - GPU Profiler: For GPU usage

---

## Continuous Integration

### GitHub Actions

Add to `.github/workflows/android-tests.yml`:

```yaml
name: Android Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Run unit tests
        run: |
          cd knowvas_flutter_client/android
          ./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest"
      
      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: knowvas_flutter_client/android/app/build/reports/tests/
```

---

## Quick Reference

### Run All Tests
```bash
# Unit tests (no device)
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest"

# Instrumented tests (requires device)
./gradlew connectedAndroidTest --tests "com.knowvas.reader.pdf.PageCurlIntegrationTest"
```

### Run Specific Test
```bash
# Unit test
./gradlew test --tests "com.knowvas.reader.pdf.Task5IntegrationCheckpointTest.testFlatMeshHasZeroDepth"

# Instrumented test
./gradlew connectedAndroidTest --tests "com.knowvas.reader.pdf.PageCurlIntegrationTest.testPerformanceTargets"
```

### Clean and Rebuild
```bash
./gradlew clean
./gradlew test
```

### View Reports
```bash
# Unit tests
open android/app/build/reports/tests/testDebugUnitTest/index.html

# Instrumented tests
open android/app/build/reports/androidTests/connected/index.html
```

---

## Expected Results

### All Tests Passing ✅

```
Task5IntegrationCheckpointTest: 12/12 tests passed ✅
PageCurlIntegrationTest: 8/8 tests passed ✅

Total: 20/20 tests passed ✅
```

### Performance Metrics ✅

```
Mesh generation: <10ms ✅
Frame render time: <33ms (30+ FPS) ✅
GPU memory: <100MB ✅
Memory leaks: None detected ✅
```

---

## Need Help?

### Documentation
- `TASK_5_CHECKPOINT_VERIFICATION.md` - Detailed verification report
- `TASK_5_COMPLETION_SUMMARY.md` - Summary of what was accomplished
- `TASK_5_VISUAL_SUMMARY.md` - Visual diagrams and charts

### Code
- `PageCurlView.kt` - Main implementation
- `MeshGenerator.kt` - Mesh generation
- `TextureManager.kt` - Texture management

### Tests
- `Task5IntegrationCheckpointTest.kt` - Unit tests
- `PageCurlIntegrationTest.kt` - Instrumented tests

---

**Ready to test!** 🧪

Run the tests to verify that Task 5 (Integration Checkpoint) is complete and the basic rendering foundation is solid.
