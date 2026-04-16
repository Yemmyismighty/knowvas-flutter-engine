import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Logger _logger = Logger();
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _metrics = {};

  /// Start tracking a performance metric
  void startTrace(String traceName) {
    _startTimes[traceName] = DateTime.now();
    if (kDebugMode) {
      developer.Timeline.startSync(traceName);
    }
  }

  /// Stop tracking a performance metric and log the duration
  void stopTrace(String traceName) {
    if (kDebugMode) {
      developer.Timeline.finishSync();
    }

    final startTime = _startTimes[traceName];
    if (startTime == null) {
      _logger.w('Trace $traceName was never started');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(traceName);

    // Store metric
    _metrics.putIfAbsent(traceName, () => []).add(duration);

    // Log metric
    _logger.i('Performance: $traceName took ${duration.inMilliseconds}ms');

    // Keep only last 100 measurements per metric
    if (_metrics[traceName]!.length > 100) {
      _metrics[traceName]!.removeAt(0);
    }
  }

  /// Measure the execution time of an async function
  Future<T> measureAsync<T>(
    String traceName,
    Future<T> Function() function,
  ) async {
    startTrace(traceName);
    try {
      return await function();
    } finally {
      stopTrace(traceName);
    }
  }

  /// Measure the execution time of a synchronous function
  T measureSync<T>(String traceName, T Function() function) {
    startTrace(traceName);
    try {
      return function();
    } finally {
      stopTrace(traceName);
    }
  }

  /// Get average duration for a metric
  Duration? getAverageDuration(String traceName) {
    final durations = _metrics[traceName];
    if (durations == null || durations.isEmpty) return null;

    final totalMs = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  /// Get all metrics summary
  Map<String, Map<String, dynamic>> getMetricsSummary() {
    final summary = <String, Map<String, dynamic>>{};

    for (final entry in _metrics.entries) {
      final durations = entry.value;
      if (durations.isEmpty) continue;

      final totalMs = durations.fold<int>(
        0,
        (sum, duration) => sum + duration.inMilliseconds,
      );
      final avgMs = totalMs ~/ durations.length;
      final minMs = durations
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a < b ? a : b);
      final maxMs = durations
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);

      summary[entry.key] = {
        'count': durations.length,
        'average_ms': avgMs,
        'min_ms': minMs,
        'max_ms': maxMs,
      };
    }

    return summary;
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
  }

  /// Log metrics summary
  void logMetricsSummary() {
    final summary = getMetricsSummary();
    if (summary.isEmpty) {
      _logger.i('No performance metrics recorded');
      return;
    }

    _logger.i('=== Performance Metrics Summary ===');
    for (final entry in summary.entries) {
      final stats = entry.value;
      _logger.i(
        '${entry.key}: avg=${stats['average_ms']}ms, '
        'min=${stats['min_ms']}ms, max=${stats['max_ms']}ms, '
        'count=${stats['count']}',
      );
    }
  }
}
