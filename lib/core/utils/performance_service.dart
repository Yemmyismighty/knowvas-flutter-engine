import 'package:logger/logger.dart';
import 'performance_monitor.dart';
import 'download_metrics.dart';
import 'crash_tracker.dart';
import 'reader_metrics.dart';

/// Unified performance monitoring service
/// 
/// This service provides a single interface for all performance monitoring
/// including app launch time, reader performance, downloads, and crash tracking.
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Logger _logger = Logger();
  
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final DownloadMetrics _downloadMetrics = DownloadMetrics();
  final CrashTracker _crashTracker = CrashTracker();
  final ReaderMetrics _readerMetrics = ReaderMetrics();
  
  bool _initialized = false;

  /// Initialize the performance service
  void initialize() {
    if (_initialized) {
      _logger.w('Performance service already initialized');
      return;
    }

    _crashTracker.initialize();
    _crashTracker.startSession();
    
    _initialized = true;
    _logger.i('Performance service initialized');
  }

  // ========== App Launch Tracking ==========

  /// Start tracking app launch time
  void startAppLaunch() {
    _performanceMonitor.startTrace('app_launch');
  }

  /// Stop tracking app launch time
  Duration? stopAppLaunch() {
    return _performanceMonitor.stopTrace('app_launch');
  }

  // ========== Reader Performance Tracking ==========

  /// Start tracking reader open time
  void startReaderOpen(int contentId, String contentType) {
    _performanceMonitor.startTrace('reader_open_${contentId}_$contentType');
    _readerMetrics.startReaderOpen(contentId, contentType);
  }

  /// Stop tracking reader open time
  Duration? stopReaderOpen(int contentId, String contentType, {bool success = true}) {
    _readerMetrics.stopReaderOpen(contentId, contentType, success: success);
    return _performanceMonitor.stopTrace('reader_open_${contentId}_$contentType');
  }

  /// Record a page turn event
  void recordPageTurn(
    int contentId,
    String contentType,
    int fromPage,
    int toPage,
    Duration latency,
  ) {
    _readerMetrics.recordPageTurn(contentId, contentType, fromPage, toPage, latency);
  }

  // ========== Download Tracking ==========

  /// Record a successful download
  void recordDownloadSuccess(
    int contentId, {
    int? fileSizeBytes,
    Duration? duration,
  }) {
    _downloadMetrics.recordSuccess(
      contentId,
      fileSizeBytes: fileSizeBytes,
      duration: duration,
    );
  }

  /// Record a failed download
  void recordDownloadFailure(
    int contentId,
    String reason, {
    String? errorDetails,
  }) {
    _downloadMetrics.recordFailure(contentId, reason, errorDetails: errorDetails);
  }

  /// Record a cancelled download
  void recordDownloadCancellation(int contentId) {
    _downloadMetrics.recordCancellation(contentId);
  }

  /// Get download success rate
  double getDownloadSuccessRate() {
    return _downloadMetrics.getSuccessRate();
  }

  // ========== Crash and Error Tracking ==========

  /// Record a non-fatal error
  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    _crashTracker.recordError(error, stackTrace, context: context);
  }

  /// Record a fatal error
  void recordFatalError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    _crashTracker.recordError(
      error,
      stackTrace,
      fatal: true,
      context: context,
    );
  }

  /// Get crash-free users percentage
  double getCrashFreePercentage() {
    return _crashTracker.getCrashFreePercentage();
  }

  // ========== Session Management ==========

  /// Start a new session
  void startSession() {
    _crashTracker.startSession();
  }

  /// End current session
  void endSession() {
    _crashTracker.endSession();
  }

  // ========== Statistics and Reporting ==========

  /// Get comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'general_performance': _performanceMonitor.getPerformanceSummary(),
      'reader_stats': _getReaderStatsMap(),
      'download_stats': _getDownloadStatsMap(),
      'crash_stats': _getCrashStatsMap(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getReaderStatsMap() {
    final stats = _readerMetrics.getStats();
    return {
      'total_reader_opens': stats.totalReaderOpens,
      'successful_opens': stats.successfulOpens,
      'failed_opens': stats.failedOpens,
      'total_page_turns': stats.totalPageTurns,
      'average_reader_open_time_ms': stats.averageReaderOpenTimeMs,
      'average_epub_open_time_ms': stats.averageEpubOpenTimeMs,
      'average_pdf_open_time_ms': stats.averagePdfOpenTimeMs,
      'average_comic_open_time_ms': stats.averageComicOpenTimeMs,
      'average_page_turn_latency_ms': stats.averagePageTurnLatencyMs,
    };
  }

  Map<String, dynamic> _getDownloadStatsMap() {
    final stats = _downloadMetrics.getStats();
    return {
      'total_downloads': stats.total,
      'successful_downloads': stats.successful,
      'failed_downloads': stats.failed,
      'cancelled_downloads': stats.cancelled,
      'success_rate': stats.successRate,
      'failure_reasons': stats.failureReasons,
    };
  }

  Map<String, dynamic> _getCrashStatsMap() {
    final stats = _crashTracker.getStats();
    return {
      'total_sessions': stats.totalSessions,
      'crash_free_sessions': stats.crashFreeSessions,
      'crash_free_percentage': stats.crashFreePercentage,
      'total_crashes': stats.totalCrashes,
      'total_errors': stats.totalErrors,
    };
  }

  /// Log all performance statistics
  void logAllStats() {
    _logger.i('========================================');
    _logger.i('    PERFORMANCE REPORT');
    _logger.i('========================================');
    
    _performanceMonitor.logPerformanceSummary();
    _logger.i('');
    
    _readerMetrics.logStats();
    _logger.i('');
    
    _downloadMetrics.logStats();
    _logger.i('');
    
    _crashTracker.logStats();
    _logger.i('========================================');
  }

  /// Clear all performance data
  void clearAllData() {
    _performanceMonitor.clearMetrics();
    _downloadMetrics.clearMetrics();
    _crashTracker.clearData();
    _readerMetrics.clearMetrics();
    
    _logger.i('All performance data cleared');
  }

  // ========== Getters for individual services ==========

  PerformanceMonitor get performanceMonitor => _performanceMonitor;
  DownloadMetrics get downloadMetrics => _downloadMetrics;
  CrashTracker get crashTracker => _crashTracker;
  ReaderMetrics get readerMetrics => _readerMetrics;
}
