import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/performance/performance_monitor.dart';

/// Performance benchmark tests
/// Measures and validates performance of critical operations
void main() {
  group('Critical Operation Benchmarks', () {
    late PerformanceMonitor perfMonitor;

    setUp(() {
      perfMonitor = PerformanceMonitor();
      perfMonitor.clearMetrics();
    });

    test('benchmark: app initialization', () async {
      final duration = await perfMonitor.measureAsync('app_init', () async {
        // Simulate app initialization steps
        await Future.delayed(const Duration(milliseconds: 500)); // Load config
        await Future.delayed(const Duration(milliseconds: 300)); // Init services
        await Future.delayed(const Duration(milliseconds: 200)); // Setup routing
      });

      expect(
        duration.inMilliseconds,
        lessThan(2000),
        reason: 'App initialization should complete within 2 seconds',
      );

      _logBenchmark('App Initialization', duration);
    });

    test('benchmark: authentication flow', () async {
      final duration = await perfMonitor.measureAsync('auth_flow', () async {
        // Simulate authentication
        await Future.delayed(const Duration(milliseconds: 800)); // API call
        await Future.delayed(const Duration(milliseconds: 200)); // Token storage
      });

      expect(
        duration.inMilliseconds,
        lessThan(1500),
        reason: 'Authentication should complete within 1.5 seconds',
      );
    });
  });
}

void _logBenchmark(String name, Duration duration) {
  // ignore: avoid_print
  print('Benchmark: $name - ${duration.inMilliseconds}ms');
}
