# Performance Monitoring Integration Guide

This guide explains how to integrate performance monitoring throughout the Knowvas Flutter app.

## Overview

The performance monitoring system tracks:
- App launch time
- Reader open time (EPUB, PDF, Comic)
- Page turn latency
- Download success rates
- Crash-free users percentage

## Components

### 1. PerformanceService
Main entry point for all performance monitoring. Provides a unified interface.

### 2. PerformanceMonitor
General-purpose performance tracking for any operation.

### 3. ReaderMetrics
Specialized tracking for reader performance (open time, page turns).

### 4. DownloadMetrics
Tracks download success rates and failure reasons.

### 5. CrashTracker
Monitors app stability and crash-free sessions.

## Usage Examples

### App Launch Tracking

Already integrated in `main.dart` and `app.dart`:

```dart
void main() {
  final performanceService = PerformanceService();
  performanceService.startAppLaunch();
  performanceService.initialize();
  
  runApp(const ProviderScope(child: KnowvasApp()));
}

// In app.dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  PerformanceService().stopAppLaunch();
});
```

### Reader Performance Tracking

Integrate in your reader state management (e.g., `reader_provider.dart`):

```dart
class ReaderNotifier extends _$ReaderNotifier {
  Future<void> openContent(int contentId, String type) async {
    // Start tracking
    PerformanceService().startReaderOpen(contentId, type);
    
    try {
      // Open reader via platform channel
      final result = await _readerChannel.openReader(
        OpenReaderRequest(
          contentId: contentId,
          type: type,
          fileUrl: fileUrl,
          token: token,
          sessionId: sessionId,
        ),
      );
      
      // Stop tracking on success
      PerformanceService().stopReaderOpen(contentId, type, success: true);
    } catch (e) {
      // Stop tracking on failure
      PerformanceService().stopReaderOpen(contentId, type, success: false);
      rethrow;
    }
  }
  
  void handlePageTurnEvent(EngagementEvent event) {
    if (event.eventType == 'page_turn') {
      // Track page turn latency
      final latency = DateTime.now().difference(event.timestamp);
      PerformanceService().recordPageTurn(
        event.contentId,
        event.contentType,
        event.fromPage ?? 0,
        event.toPage ?? 0,
        latency,
      );
    }
  }
}
```

### Download Tracking

Integrate in your download manager (e.g., `download_manager.dart`):

```dart
class DownloadManager {
  Future<void> downloadContent({
    required int contentId,
    required String signedUrl,
    void Function(double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Perform download
      final response = await _dio.download(
        signedUrl,
        savePath,
        onReceiveProgress: (received, total) {
          onProgress?.call(received / total);
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      final fileSize = response.data?.length;
      
      // Record success
      PerformanceService().recordDownloadSuccess(
        contentId,
        fileSizeBytes: fileSize,
        duration: duration,
      );
    } catch (e) {
      // Record failure
      String reason = 'unknown_error';
      if (e is DioException) {
        reason = e.type.toString();
      }
      
      PerformanceService().recordDownloadFailure(
        contentId,
        reason,
        errorDetails: e.toString(),
      );
      rethrow;
    }
  }
  
  Future<void> cancelDownload(int contentId) async {
    // Cancel download logic...
    
    PerformanceService().recordDownloadCancellation(contentId);
  }
}
```

### Error Tracking

Integrate throughout the app for error handling:

```dart
// Non-fatal errors
try {
  await someOperation();
} catch (e, stackTrace) {
  PerformanceService().recordError(e, stackTrace, context: 'someOperation');
  // Handle error gracefully
}

// Fatal errors (that crash the app)
try {
  await criticalOperation();
} catch (e, stackTrace) {
  PerformanceService().recordFatalError(
    e,
    stackTrace,
    context: 'criticalOperation',
  );
  rethrow;
}
```

### Session Management

Integrate in app lifecycle (e.g., in `app.dart` or a lifecycle observer):

```dart
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PerformanceService().startSession();
    } else if (state == AppLifecycleState.paused) {
      PerformanceService().endSession();
    }
  }
}
```

### Getting Performance Reports

```dart
// Get comprehensive report
final report = PerformanceService().getPerformanceReport();
print(report);

// Log all statistics
PerformanceService().logAllStats();

// Get specific metrics
final downloadSuccessRate = PerformanceService().getDownloadSuccessRate();
final crashFreePercentage = PerformanceService().getCrashFreePercentage();

print('Download success rate: ${downloadSuccessRate.toStringAsFixed(2)}%');
print('Crash-free percentage: ${crashFreePercentage.toStringAsFixed(2)}%');
```

### Viewing Performance Data in Settings

You can create a developer settings screen to view performance data:

```dart
class DeveloperSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Performance Metrics')),
      body: ListView(
        children: [
          ListTile(
            title: Text('View Performance Report'),
            onTap: () {
              final report = PerformanceService().getPerformanceReport();
              // Display report in a dialog or new screen
            },
          ),
          ListTile(
            title: Text('Log All Stats'),
            onTap: () {
              PerformanceService().logAllStats();
            },
          ),
          ListTile(
            title: Text('Clear All Data'),
            onTap: () {
              PerformanceService().clearAllData();
            },
          ),
        ],
      ),
    );
  }
}
```

## Performance Thresholds

The following thresholds are configured:

- **App Launch**: 3000ms (3 seconds)
- **Reader Open**: 4000ms (4 seconds)
- **Page Turn**: 100ms

When operations exceed these thresholds, warnings are logged.

## Best Practices

1. **Always track reader operations**: Start tracking before opening a reader and stop after it's ready or fails.

2. **Track all downloads**: Record success, failure, and cancellation for every download.

3. **Record errors with context**: Always provide context when recording errors to help with debugging.

4. **Review metrics regularly**: Periodically check performance reports to identify bottlenecks.

5. **Don't track too much**: Only track operations that are critical to user experience.

6. **Clear old data**: Implement a strategy to clear old performance data to prevent memory issues.

## Integration Checklist

- [x] App launch tracking in `main.dart` and `app.dart`
- [ ] Reader open tracking in reader state management
- [ ] Page turn tracking in reader event handlers
- [ ] Download tracking in download manager
- [ ] Error tracking in critical operations
- [ ] Session management in app lifecycle
- [ ] Performance report viewing in settings (optional)

## Future Enhancements

Consider adding:
- Remote analytics integration (Firebase, Sentry, etc.)
- Automatic performance report uploads
- Performance alerts for degraded metrics
- A/B testing support
- Custom performance traces for specific features
