import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../performance/memory_monitor.dart';
import '../performance/performance_monitor.dart';
import '../utils/image_optimizer.dart';

/// App initialization and optimization configuration
class AppInitializer {
  static bool _initialized = false;

  /// Initialize app with performance optimizations
  static Future<void> initialize() async {
    if (_initialized) return;

    final monitor = PerformanceMonitor();
    monitor.startTrace('app_initialization');

    try {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Configure image cache for optimal memory usage
      _configureImageCache();

      // Set preferred orientations
      await _setPreferredOrientations();

      // Configure system UI
      _configureSystemUI();

      // Start memory monitoring in debug mode
      if (kDebugMode) {
        _startMemoryMonitoring();
      }

      // Configure error handling
      _configureErrorHandling();

      _initialized = true;
      debugPrint('✅ App initialization complete');
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      rethrow;
    } finally {
      monitor.stopTrace('app_initialization');
    }
  }

  /// Configure image cache for optimal memory usage
  static void _configureImageCache() {
    final config = ImageOptimizer.getOptimalCacheConfig();
    config.apply();

    debugPrint('📸 Image cache configured: '
        '${config.maxByteSize ~/ (1024 * 1024)}MB, '
        '${config.maxImageCount} images');
  }

  /// Set preferred device orientations
  static Future<void> _setPreferredOrientations() async {
    // Allow all orientations for tablets, portrait for phones
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Configure system UI overlay style
  static void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Start memory monitoring in debug mode
  static void _startMemoryMonitoring() {
    final memoryMonitor = MemoryMonitor();
    memoryMonitor.startMonitoring(
      interval: const Duration(seconds: 30),
    );
    debugPrint('🔍 Memory monitoring started');
  }

  /// Configure error handling
  static void _configureErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      
      // Log error for debugging
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');

      // In production, send to crash reporting service
      if (kReleaseMode) {
        // TODO: Send to Firebase Crashlytics or Sentry
        // FirebaseCrashlytics.instance.recordFlutterError(details);
      }
    };

    // Handle errors outside Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');

      // In production, send to crash reporting service
      if (kReleaseMode) {
        // TODO: Send to crash reporting service
      }

      return true;
    };
  }

  /// Clean up resources on app termination
  static Future<void> dispose() async {
    // Stop memory monitoring
    MemoryMonitor().stopMonitoring();

    // Clear image cache
    ImageOptimizer.clearImageCache();

    // Log performance metrics
    if (kDebugMode) {
      PerformanceMonitor().logMetricsSummary();
    }

    debugPrint('🧹 App cleanup complete');
  }
}
