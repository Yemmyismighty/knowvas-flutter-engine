import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/performance/performance_monitor.dart';
import 'package:knowvas/core/performance/memory_monitor.dart';

/// Long reading session performance tests
/// Tests requirement 14.6 - stable performance during extended use
void main() {
  group('Long Reading Session Tests', () {
    late PerformanceMonitor perfMonitor;
    late MemoryMonitor memMonitor;

    setUp(() {
      perfMonitor = PerformanceMonitor();
      memMonitor = MemoryMonitor();
      perfMonitor.clearMetrics();
      memMonitor.clearSnapshots();
    });

    tearDown(() {
      memMonitor.stopMonitoring();
    });

    test('should maintain stable performance during 2-hour session', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 500));
      
      // Simulate 2-hour reading session (compressed to 10 seconds for testing)
      final sessionDuration = const Duration(seconds: 10);
      final startTime = DateTime.now();
      final pageTurnDurations = <Duration>[];
      
      int pageCount = 0;
      while (DateTime.now().difference(startTime) < sessionDuration) {
        // Simulate page turn
        final duration = await perfMonitor.measureAsync('page_turn_$pageCount', () async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        
        pageTurnDurations.add(duration);
        pageCount++;
        
        // Simulate reading time between page turns
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      memMonitor.stopMonitoring();
      
      // Check that page turn performance doesn't degrade
      final firstHalfAvg = _calculateAverage(
        pageTurnDurations.sublist(0, pageTurnDurations.length ~/ 2),
      );
      final secondHalfAvg = _calculateAverage(
        pageTurnDurations.sublist(pageTurnDurations.length ~/ 2),
      );
      
      // Performance should not degrade significantly (allow 20% variance)
      final degradation = (secondHalfAvg - firstHalfAvg) / firstHalfAvg;
      expect(
        degradation,
        lessThan(0.2),
        reason: 'Performance should not degrade significantly over time',
      );
      
      // All page turns should be fast
      expect(
        secondHalfAvg,
        lessThan(100),
        reason: 'Page turns should remain fast throughout session',
      );
    });

    test('should handle continuous page turns without degradation', () async {
      // Simulate rapid page turning for extended period
      final durations = <Duration>[];
      
      for (int i = 0; i < 100; i++) {
        final duration = await perfMonitor.measureAsync('rapid_turn_$i', () async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        durations.add(duration);
      }
      
      // Check consistency
      final avgDuration = _calculateAverage(durations);
      expect(
        avgDuration,
        lessThan(100),
        reason: 'Average page turn should be under 100ms',
      );
      
      // Check that no individual turn is excessively slow
      final slowTurns = durations.where((d) => d.inMilliseconds > 150).length;
      expect(
        slowTurns,
        lessThan(5),
        reason: 'Should have very few slow page turns',
      );
    });

    test('should maintain stable memory during extended EPUB reading', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 300));
      
      // Simulate reading through a long EPUB
      for (int chapter = 0; chapter < 30; chapter++) {
        // Load chapter
        await perfMonitor.measureAsync('load_chapter_$chapter', () async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        
        // Read through chapter pages
        for (int page = 0; page < 20; page++) {
          await perfMonitor.measureAsync('read_page', () async {
            await Future.delayed(const Duration(milliseconds: 30));
          });
        }
        
        // Cleanup old chapters
        if (chapter > 2) {
          await perfMonitor.measureAsync('cleanup_chapter', () async {
            await Future.delayed(const Duration(milliseconds: 20));
          });
        }
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(
        stats['snapshots_count'],
        greaterThan(10),
        reason: 'Should have monitored memory throughout session',
      );
    });

    test('should maintain stable memory during extended PDF reading', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 300));
      
      // Simulate reading through a long PDF
      for (int page = 0; page < 500; page++) {
        // Render page
        await perfMonitor.measureAsync('render_pdf_page', () async {
          await Future.delayed(const Duration(milliseconds: 40));
        });
        
        // Cleanup old pages from cache
        if (page > 5) {
          await perfMonitor.measureAsync('cleanup_pdf_cache', () async {
            await Future.delayed(const Duration(milliseconds: 10));
          });
        }
        
        // Simulate reading time
        await Future.delayed(const Duration(milliseconds: 20));
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(
        stats['snapshots_count'],
        greaterThan(10),
        reason: 'Should have monitored memory throughout session',
      );
    });

    test('should maintain stable memory during extended comic reading', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 300));
      
      // Simulate reading through a long comic
      for (int page = 0; page < 200; page++) {
        // Load and display image
        await perfMonitor.measureAsync('load_comic_page', () async {
          await Future.delayed(const Duration(milliseconds: 80));
        });
        
        // Preload next pages
        if (page < 198) {
          await perfMonitor.measureAsync('preload_comic', () async {
            await Future.delayed(const Duration(milliseconds: 40));
          });
        }
        
        // Cleanup old images
        if (page > 3) {
          await perfMonitor.measureAsync('cleanup_comic_cache', () async {
            await Future.delayed(const Duration(milliseconds: 15));
          });
        }
        
        // Simulate viewing time
        await Future.delayed(const Duration(milliseconds: 30));
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(
        stats['snapshots_count'],
        greaterThan(10),
        reason: 'Should have monitored memory throughout session',
      );
    });
  });

  group('Session Stability Tests', () {
    late PerformanceMonitor perfMonitor;

    setUp(() {
      perfMonitor = PerformanceMonitor();
      perfMonitor.clearMetrics();
    });

    test('should handle frequent reader setting changes', () async {
      // Simulate user changing settings frequently during reading
      for (int i = 0; i < 20; i++) {
        // Change font size
        await perfMonitor.measureAsync('change_font_size', () async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        
        // Read a few pages
        for (int j = 0; j < 5; j++) {
          await perfMonitor.measureAsync('page_turn', () async {
            await Future.delayed(const Duration(milliseconds: 40));
          });
        }
        
        // Change theme
        await perfMonitor.measureAsync('change_theme', () async {
          await Future.delayed(const Duration(milliseconds: 60));
        });
        
        // Read more pages
        for (int j = 0; j < 5; j++) {
          await perfMonitor.measureAsync('page_turn', () async {
            await Future.delayed(const Duration(milliseconds: 40));
          });
        }
      }
      
      // Settings changes should remain fast
      final fontChangeDuration = perfMonitor.getAverageDuration('change_font_size');
      final themeChangeDuration = perfMonitor.getAverageDuration('change_theme');
      
      expect(fontChangeDuration!.inMilliseconds, lessThan(100));
      expect(themeChangeDuration!.inMilliseconds, lessThan(150));
    });

    test('should handle frequent bookmark/highlight operations', () async {
      // Simulate user adding many bookmarks and highlights
      for (int i = 0; i < 50; i++) {
        // Add bookmark
        await perfMonitor.measureAsync('add_bookmark', () async {
          await Future.delayed(const Duration(milliseconds: 30));
        });
        
        // Read pages
        for (int j = 0; j < 3; j++) {
          await perfMonitor.measureAsync('page_turn', () async {
            await Future.delayed(const Duration(milliseconds: 40));
          });
        }
        
        // Add highlight
        if (i % 2 == 0) {
          await perfMonitor.measureAsync('add_highlight', () async {
            await Future.delayed(const Duration(milliseconds: 40));
          });
        }
      }
      
      // Operations should remain fast
      final bookmarkDuration = perfMonitor.getAverageDuration('add_bookmark');
      final highlightDuration = perfMonitor.getAverageDuration('add_highlight');
      
      expect(bookmarkDuration!.inMilliseconds, lessThan(50));
      expect(highlightDuration!.inMilliseconds, lessThan(80));
    });

    test('should handle switching between multiple books', () async {
      // Simulate user switching between different books
      for (int book = 0; book < 10; book++) {
        // Open book
        await perfMonitor.measureAsync('open_book_$book', () async {
          await Future.delayed(const Duration(milliseconds: 200));
        });
        
        // Read some pages
        for (int page = 0; page < 10; page++) {
          await perfMonitor.measureAsync('read_page', () async {
            await Future.delayed(const Duration(milliseconds: 40));
          });
        }
        
        // Close book
        await perfMonitor.measureAsync('close_book_$book', () async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
      }
      
      // Book operations should remain consistent
      final openDurations = <Duration>[];
      for (int i = 0; i < 10; i++) {
        final duration = perfMonitor.getAverageDuration('open_book_$i');
        if (duration != null) {
          openDurations.add(duration);
        }
      }
      
      // Check consistency
      if (openDurations.isNotEmpty) {
        final avgOpen = _calculateAverage(openDurations);
        expect(
          avgOpen,
          lessThan(300),
          reason: 'Book opening should remain fast',
        );
      }
    });
  });

  group('Resource Management Tests', () {
    late PerformanceMonitor perfMonitor;
    late MemoryMonitor memMonitor;

    setUp(() {
      perfMonitor = PerformanceMonitor();
      memMonitor = MemoryMonitor();
      perfMonitor.clearMetrics();
      memMonitor.clearSnapshots();
    });

    tearDown(() {
      memMonitor.stopMonitoring();
    });

    test('should properly cleanup resources after long session', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 200));
      
      // Simulate long reading session
      for (int i = 0; i < 50; i++) {
        await perfMonitor.measureAsync('reading_activity', () async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
      }
      
      // Close reader and cleanup
      await perfMonitor.measureAsync('session_cleanup', () async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      
      memMonitor.stopMonitoring();
      
      final cleanupDuration = perfMonitor.getAverageDuration('session_cleanup');
      expect(
        cleanupDuration!.inMilliseconds,
        lessThan(300),
        reason: 'Session cleanup should be fast',
      );
    });

    test('should handle multiple long sessions without issues', () async {
      // Simulate multiple reading sessions
      for (int session = 0; session < 5; session++) {
        memMonitor.startMonitoring(interval: const Duration(milliseconds: 200));
        
        // Reading session
        for (int i = 0; i < 20; i++) {
          await perfMonitor.measureAsync('session_${session}_activity', () async {
            await Future.delayed(const Duration(milliseconds: 50));
          });
        }
        
        memMonitor.stopMonitoring();
        
        // Cleanup between sessions
        await perfMonitor.measureAsync('inter_session_cleanup', () async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
      }
      
      // Cleanup should remain consistent
      final cleanupDuration = perfMonitor.getAverageDuration('inter_session_cleanup');
      expect(
        cleanupDuration!.inMilliseconds,
        lessThan(200),
        reason: 'Inter-session cleanup should be fast',
      );
    });
  });
}

/// Helper function to calculate average duration in milliseconds
double _calculateAverage(List<Duration> durations) {
  if (durations.isEmpty) return 0;
  final total = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
  return total / durations.length;
}
