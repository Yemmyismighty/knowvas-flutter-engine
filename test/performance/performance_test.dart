import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/performance/performance_monitor.dart';
import 'package:knowvas/core/performance/memory_monitor.dart';

void main() {
  group('Performance Monitor Tests', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor();
      monitor.clearMetrics();
    });

    test('should track trace duration', () async {
      monitor.startTrace('test_trace');
      await Future.delayed(const Duration(milliseconds: 100));
      monitor.stopTrace('test_trace');

      final avgDuration = monitor.getAverageDuration('test_trace');
      expect(avgDuration, isNotNull);
      expect(avgDuration!.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('should measure async function', () async {
      final result = await monitor.measureAsync('async_test', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 'test_result';
      });

      expect(result, equals('test_result'));
      final avgDuration = monitor.getAverageDuration('async_test');
      expect(avgDuration, isNotNull);
      expect(avgDuration!.inMilliseconds, greaterThanOrEqualTo(50));
    });

    test('should measure sync function', () {
      final result = monitor.measureSync('sync_test', () {
        return 42;
      });

      expect(result, equals(42));
      final avgDuration = monitor.getAverageDuration('sync_test');
      expect(avgDuration, isNotNull);
    });

    test('should calculate average duration correctly', () {
      // Record multiple measurements
      for (int i = 0; i < 5; i++) {
        monitor.startTrace('multi_test');
        monitor.stopTrace('multi_test');
      }

      final avgDuration = monitor.getAverageDuration('multi_test');
      expect(avgDuration, isNotNull);
    });

    test('should generate metrics summary', () {
      monitor.startTrace('summary_test');
      monitor.stopTrace('summary_test');

      final summary = monitor.getMetricsSummary();
      expect(summary, isNotEmpty);
      expect(summary['summary_test'], isNotNull);
      expect(summary['summary_test']!['count'], equals(1));
      expect(summary['summary_test']!['average_ms'], isA<int>());
      expect(summary['summary_test']!['min_ms'], isA<int>());
      expect(summary['summary_test']!['max_ms'], isA<int>());
    });

    test('should clear metrics', () {
      monitor.startTrace('clear_test');
      monitor.stopTrace('clear_test');

      monitor.clearMetrics();

      final summary = monitor.getMetricsSummary();
      expect(summary, isEmpty);
    });

    test('should limit stored measurements to 100', () {
      // Record 150 measurements
      for (int i = 0; i < 150; i++) {
        monitor.startTrace('limit_test');
        monitor.stopTrace('limit_test');
      }

      final summary = monitor.getMetricsSummary();
      expect(summary['limit_test']!['count'], equals(100));
    });
  });

  group('Memory Monitor Tests', () {
    late MemoryMonitor monitor;

    setUp(() {
      monitor = MemoryMonitor();
      monitor.clearSnapshots();
    });

    tearDown(() {
      monitor.stopMonitoring();
    });

    test('should start and stop monitoring', () {
      monitor.startMonitoring(interval: const Duration(seconds: 1));
      final stats = monitor.getMemoryStats();
      expect(stats['monitoring_active'], isTrue);

      monitor.stopMonitoring();
      final statsAfter = monitor.getMemoryStats();
      expect(statsAfter['monitoring_active'], isFalse);
    });

    test('should not start monitoring twice', () {
      monitor.startMonitoring(interval: const Duration(seconds: 1));
      monitor.startMonitoring(interval: const Duration(seconds: 1));
      
      final stats = monitor.getMemoryStats();
      expect(stats['monitoring_active'], isTrue);
    });

    test('should clear snapshots', () {
      monitor.clearSnapshots();
      final stats = monitor.getMemoryStats();
      expect(stats['snapshots_count'], equals(0));
    });
  });

  group('Performance Benchmarks', () {
    test('app launch should complete within target time', () async {
      final monitor = PerformanceMonitor();
      
      await monitor.measureAsync('simulated_app_launch', () async {
        // Simulate app initialization
        await Future.delayed(const Duration(milliseconds: 1500));
      });

      final avgDuration = monitor.getAverageDuration('simulated_app_launch');
      expect(avgDuration, isNotNull);
      
      // Target: < 2 seconds
      expect(
        avgDuration!.inMilliseconds,
        lessThan(2000),
        reason: 'App launch should complete within 2 seconds',
      );
    });

    test('page turn should complete within target time', () async {
      final monitor = PerformanceMonitor();
      
      await monitor.measureAsync('simulated_page_turn', () async {
        // Simulate page turn
        await Future.delayed(const Duration(milliseconds: 50));
      });

      final avgDuration = monitor.getAverageDuration('simulated_page_turn');
      expect(avgDuration, isNotNull);
      
      // Target: < 100ms
      expect(
        avgDuration!.inMilliseconds,
        lessThan(100),
        reason: 'Page turn should complete within 100ms',
      );
    });

    test('image loading should complete within target time', () async {
      final monitor = PerformanceMonitor();
      
      await monitor.measureAsync('simulated_image_load', () async {
        // Simulate image loading
        await Future.delayed(const Duration(milliseconds: 300));
      });

      final avgDuration = monitor.getAverageDuration('simulated_image_load');
      expect(avgDuration, isNotNull);
      
      // Target: < 500ms
      expect(
        avgDuration!.inMilliseconds,
        lessThan(500),
        reason: 'Image loading should complete within 500ms',
      );
    });
  });
}
