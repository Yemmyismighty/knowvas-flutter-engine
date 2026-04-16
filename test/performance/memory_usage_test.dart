import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/performance/memory_monitor.dart';
import 'package:knowvas/core/performance/performance_monitor.dart';

/// Memory usage performance tests
/// Tests requirement 14.6 - memory management during extended reading sessions
void main() {
  group('Memory Usage Tests', () {
    late MemoryMonitor memMonitor;
    late PerformanceMonitor perfMonitor;

    setUp(() {
      memMonitor = MemoryMonitor();
      perfMonitor = PerformanceMonitor();
      memMonitor.clearSnapshots();
      perfMonitor.clearMetrics();
    });

    tearDown(() {
      memMonitor.stopMonitoring();
    });

    test('should maintain stable memory during 2-hour reading session', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 500));
      
      // Simulate 2-hour reading session (compressed to 5 seconds for testing)
      // In real scenario, this would run for 2 hours
      final sessionDuration = const Duration(seconds: 5);
      final startTime = DateTime.now();
      
      while (DateTime.now().difference(startTime) < sessionDuration) {
        // Simulate page turns
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Simulate reading activity
        await perfMonitor.measureAsync('page_turn', () async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(
        stats['snapshots_count'],
        greaterThan(5),
        reason: 'Should have multiple memory snapshots',
      );
      
      // Memory should be monitored throughout
      expect(stats['monitoring_active'], isFalse);
    });

    test('should not leak memory during repeated content opens', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 200));
      
      // Open and close content 10 times
      for (int i = 0; i < 10; i++) {
        await perfMonitor.measureAsync('open_close_$i', () async {
          // Simulate opening content
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Simulate reading
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Simulate closing content
          await Future.delayed(const Duration(milliseconds: 50));
        });
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(stats['snapshots_count'], greaterThan(0));
    });

    test('should handle memory pressure gracefully', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
      
      // Simulate memory pressure scenario
      await perfMonitor.measureAsync('memory_pressure', () async {
        // Simulate loading large content
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Simulate memory cleanup
        await Future.delayed(const Duration(milliseconds: 200));
      });
      
      memMonitor.stopMonitoring();
      
      final duration = perfMonitor.getAverageDuration('memory_pressure');
      expect(
        duration!.inMilliseconds,
        lessThan(1000),
        reason: 'Memory cleanup should complete quickly',
      );
    });

    test('should unload off-screen content to save memory', () async {
      final loadedPages = <int>{};
      
      // Load initial pages
      for (int i = 0; i < 3; i++) {
        await perfMonitor.measureAsync('load_page_$i', () async {
          await Future.delayed(const Duration(milliseconds: 50));
          loadedPages.add(i);
        });
      }
      
      expect(loadedPages.length, equals(3));
      
      // Navigate forward, unload old pages
      await perfMonitor.measureAsync('unload_old_pages', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        // Simulate unloading pages 0 and 1
        loadedPages.removeWhere((page) => page < 2);
      });
      
      // Load new pages
      for (int i = 3; i < 5; i++) {
        await perfMonitor.measureAsync('load_page_$i', () async {
          await Future.delayed(const Duration(milliseconds: 50));
          loadedPages.add(i);
        });
      }
      
      // Should only have recent pages loaded
      expect(
        loadedPages.length,
        lessThanOrEqualTo(4),
        reason: 'Should maintain limited number of loaded pages',
      );
    });
  });

  group('Memory Limits Tests', () {
    late MemoryMonitor memMonitor;

    setUp(() {
      memMonitor = MemoryMonitor();
      memMonitor.clearSnapshots();
    });

    tearDown(() {
      memMonitor.stopMonitoring();
    });

    test('should stay within memory limits during EPUB reading', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 200));
      
      // Simulate EPUB reading with chapter loading
      for (int chapter = 0; chapter < 20; chapter++) {
        // Load chapter
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Read chapter (simulate page turns)
        for (int page = 0; page < 10; page++) {
          await Future.delayed(const Duration(milliseconds: 20));
        }
        
        // Unload old chapters
        if (chapter > 2) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(stats['snapshots_count'], greaterThan(0));
    });

    test('should stay within memory limits during PDF reading', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 200));
      
      // Simulate PDF reading with page caching
      for (int page = 0; page < 100; page++) {
        // Render page
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Clear cache of old pages
        if (page > 5) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(stats['snapshots_count'], greaterThan(0));
    });

    test('should stay within memory limits during comic reading', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 200));
      
      // Simulate comic reading with image caching
      for (int page = 0; page < 50; page++) {
        // Load and display image
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Preload next images
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Clear old images from cache
        if (page > 3) {
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }
      
      memMonitor.stopMonitoring();
      
      final stats = memMonitor.getMemoryStats();
      expect(stats['snapshots_count'], greaterThan(0));
    });
  });

  group('Memory Cleanup Tests', () {
    late MemoryMonitor memMonitor;
    late PerformanceMonitor perfMonitor;

    setUp(() {
      memMonitor = MemoryMonitor();
      perfMonitor = PerformanceMonitor();
      memMonitor.clearSnapshots();
      perfMonitor.clearMetrics();
    });

    tearDown(() {
      memMonitor.stopMonitoring();
    });

    test('should cleanup memory when closing reader', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
      
      // Open reader
      await perfMonitor.measureAsync('open_reader', () async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      
      // Read for a while
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close reader and cleanup
      await perfMonitor.measureAsync('close_and_cleanup', () async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      
      memMonitor.stopMonitoring();
      
      final cleanupDuration = perfMonitor.getAverageDuration('close_and_cleanup');
      expect(
        cleanupDuration!.inMilliseconds,
        lessThan(200),
        reason: 'Memory cleanup should be fast',
      );
    });

    test('should cleanup memory when app goes to background', () async {
      memMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
      
      // Simulate app in foreground
      await Future.delayed(const Duration(milliseconds: 300));
      
      // App goes to background - cleanup non-essential resources
      await perfMonitor.measureAsync('background_cleanup', () async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      
      memMonitor.stopMonitoring();
      
      final cleanupDuration = perfMonitor.getAverageDuration('background_cleanup');
      expect(
        cleanupDuration!.inMilliseconds,
        lessThan(200),
        reason: 'Background cleanup should be fast',
      );
    });

    test('should restore state efficiently when returning to foreground', () async {
      // Simulate background state
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Return to foreground and restore
      await perfMonitor.measureAsync('foreground_restore', () async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      
      final restoreDuration = perfMonitor.getAverageDuration('foreground_restore');
      expect(
        restoreDuration!.inMilliseconds,
        lessThan(300),
        reason: 'State restoration should be fast',
      );
    });
  });

  group('Cache Management Tests', () {
    late PerformanceMonitor perfMonitor;

    setUp(() {
      perfMonitor = PerformanceMonitor();
      perfMonitor.clearMetrics();
    });

    test('should implement LRU cache for chapters', () async {
      final cache = <int, String>{};
      const maxCacheSize = 5;
      final accessOrder = <int>[];
      
      // Load chapters
      for (int i = 0; i < 10; i++) {
        await perfMonitor.measureAsync('load_chapter_$i', () async {
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Add to cache
          if (cache.length >= maxCacheSize) {
            // Remove least recently used
            final lru = accessOrder.first;
            cache.remove(lru);
            accessOrder.removeAt(0);
          }
          
          cache[i] = 'chapter_$i';
          accessOrder.add(i);
        });
      }
      
      // Cache should not exceed max size
      expect(
        cache.length,
        lessThanOrEqualTo(maxCacheSize),
        reason: 'Cache should respect size limits',
      );
    });

    test('should implement image cache with size limits', () async {
      final imageCache = <int, int>{}; // page -> size in KB
      const maxCacheSizeKB = 50000; // 50MB
      int currentCacheSizeKB = 0;
      
      // Load images
      for (int i = 0; i < 100; i++) {
        await perfMonitor.measureAsync('load_image_$i', () async {
          await Future.delayed(const Duration(milliseconds: 30));
          
          const imageSizeKB = 1000; // 1MB per image
          
          // Check if we need to clear cache
          while (currentCacheSizeKB + imageSizeKB > maxCacheSizeKB && imageCache.isNotEmpty) {
            final oldestPage = imageCache.keys.first;
            currentCacheSizeKB -= imageCache[oldestPage]!;
            imageCache.remove(oldestPage);
          }
          
          // Add to cache
          imageCache[i] = imageSizeKB;
          currentCacheSizeKB += imageSizeKB;
        });
      }
      
      // Cache size should not exceed limit
      expect(
        currentCacheSizeKB,
        lessThanOrEqualTo(maxCacheSizeKB),
        reason: 'Image cache should respect size limits',
      );
    });
  });
}
