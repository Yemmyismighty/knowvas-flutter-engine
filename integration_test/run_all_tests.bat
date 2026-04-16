@echo off
REM Script to run all integration tests on Windows
REM Usage: run_all_tests.bat [device_id]

setlocal

set DEVICE_ID=%1

echo =========================================
echo Running Knowvas Integration Tests
echo =========================================
echo.

if "%DEVICE_ID%"=="" (
    echo No device specified. Using default device.
    set DEVICE_ARG=
) else (
    echo Using device: %DEVICE_ID%
    set DEVICE_ARG=-d %DEVICE_ID%
)

echo.
echo 1. Running basic app integration tests...
echo -----------------------------------------
flutter test integration_test/app_test.dart %DEVICE_ARG%

echo.
echo 2. Running reader integration tests...
echo -----------------------------------------
flutter test integration_test/reader_integration_test.dart %DEVICE_ARG%

echo.
echo 3. Running complete E2E journey tests...
echo -----------------------------------------
flutter test integration_test/e2e_complete_journey_test.dart %DEVICE_ARG%

echo.
echo 4. Running multi-device tests...
echo -----------------------------------------
flutter test integration_test/multi_device_test.dart %DEVICE_ARG%

echo.
echo =========================================
echo All integration tests completed!
echo =========================================

endlocal
