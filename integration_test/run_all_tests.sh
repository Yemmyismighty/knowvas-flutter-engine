#!/bin/bash

# Script to run all integration tests
# Usage: ./run_all_tests.sh [device_id]

set -e

DEVICE_ID=$1

echo "========================================="
echo "Running Knowvas Integration Tests"
echo "========================================="
echo ""

# Check if device is specified
if [ -z "$DEVICE_ID" ]; then
    echo "No device specified. Using default device."
    DEVICE_ARG=""
else
    echo "Using device: $DEVICE_ID"
    DEVICE_ARG="-d $DEVICE_ID"
fi

echo ""
echo "1. Running basic app integration tests..."
echo "-----------------------------------------"
flutter test integration_test/app_test.dart $DEVICE_ARG

echo ""
echo "2. Running reader integration tests..."
echo "-----------------------------------------"
flutter test integration_test/reader_integration_test.dart $DEVICE_ARG

echo ""
echo "3. Running complete E2E journey tests..."
echo "-----------------------------------------"
flutter test integration_test/e2e_complete_journey_test.dart $DEVICE_ARG

echo ""
echo "4. Running multi-device tests..."
echo "-----------------------------------------"
flutter test integration_test/multi_device_test.dart $DEVICE_ARG

echo ""
echo "========================================="
echo "All integration tests completed!"
echo "========================================="
