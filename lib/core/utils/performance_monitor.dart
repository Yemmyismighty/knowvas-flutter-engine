import 'dart:async';
import 'package:logger/logger.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Logger _logger = Logger();
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _metrics = {};
  
  // Performance thresholds (in milliseconds)
  static const int appLaunchThreshold = 3000;
  static const int readerOpenThreshold = 4000;
  static const int pageTurnThreshold = 100;

  /// Start tracking a performance metric
  void startTrace(String traceName) {
    _startTimes[traceName] = DateTime.now();
    _logger.d('Performance trace started: $traceName');
  }

  /// Stop tracking a performance metric and log the duration
  Duration? stopTrace(String traceName) {
    final startTime = _startTimes.remove(traceName);
    if (startTime == null) {
      _logger.w('No start time found for trace: $traceName');
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    _recordMetric(traceName, duration);
    
    _logger.i('Performance trace completed: $traceName - ${duration.inMilliseconds}ms');
    
    // Check against thresholds
    _checkThreshold(traceName, duration);
    
    return duration;
  }

  /// Record a metric value
  void _recordMetric(String metricName, Duration duration) {
    if (!_metrics.containsKey(metricName)) {
      _metrics[metricName] = [];
    }
    _metrics[metricName]!.add(duration);
  }

  /// Check if duration exceeds threshold
  void _checkThreshold(String traceName, Duration duration) {
    int? threshold;
    
    if (traceName.contains('app_launch')) {
      threshold = appLaunchThreshold;
    } else if (traceName.contains('reader_open')) {
      threshold = readerOpenThreshold;
    } else if (traceName.contains('page_turn')) {
      threshold = pageTurnThreshold;
    }

    if (threshold != null && duration.inMilliseconds > threshold) {
      _logger.w(
        'Performance warning: $traceName took ${duration.inMilliseconds}ms '
        '(threshold: ${threshold}ms)',
      );
    }
  }

  /// Get average duration for a metric
  Duration? getAverageMetric(String metricName) {
    final metrics = _metrics[metricName];
    if (metrics == null || metrics.isEmpty) {
      return null;
    }

    final totalMs = metrics.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ metrics.length);
  }

  /// Get all recorded metrics for a specific trace
  List<Duration>? getMetrics(String metricName) {
    return _metrics[metricName];
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
    _logger.d('All performance metrics cleared');
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};
    
    for (final entry in _metrics.entries) {
      final metricName = entry.key;
      final durations = entry.value;
      
      if (durations.isEmpty) continue;
      
      final totalMs = durations.fold<int>(
        0,
        (sum, duration) => sum + duration.inMilliseconds,
      );
      final avgMs = totalMs ~/ durations.length;
      final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
      final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
      
      summary[metricName] = {
        'count': durations.length,
        'average_ms': avgMs,
        'min_ms': minMs,
        'max_ms': maxMs,
        'total_ms': totalMs,
      };
    }
    
    return summary;
  }

  /// Log performance summary
  void logPerformanceSummary() {
    final summary = getPerformanceSummary();
    _logger.i('=== Performance Summary ===');
    
    for (final entry in summary.entries) {
      final metricName = entry.key;
      final stats = entry.value as Map<String, dynamic>;
      
      _logger.i(
        '$metricName: '
        'count=${stats['count']}, '
        'avg=${stats['average_ms']}ms, '
        'min=${stats['min_ms']}ms, '
        'max=${stats['max_ms']}ms',
      );
    }
  }
}
