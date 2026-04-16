import 'package:logger/logger.dart';

/// Tracks download success rates and metrics
class DownloadMetrics {
  static final DownloadMetrics _instance = DownloadMetrics._internal();
  factory DownloadMetrics() => _instance;
  DownloadMetrics._internal();

  final Logger _logger = Logger();
  
  int _totalDownloads = 0;
  int _successfulDownloads = 0;
  int _failedDownloads = 0;
  int _cancelledDownloads = 0;
  
  final Map<String, int> _failureReasons = {};
  final List<DownloadRecord> _recentDownloads = [];
  static const int maxRecentDownloads = 100;

  /// Record a successful download
  void recordSuccess(int contentId, {int? fileSizeBytes, Duration? duration}) {
    _totalDownloads++;
    _successfulDownloads++;
    
    _recentDownloads.add(DownloadRecord(
      contentId: contentId,
      success: true,
      timestamp: DateTime.now(),
      fileSizeBytes: fileSizeBytes,
      duration: duration,
    ));
    
    _trimRecentDownloads();
    
    _logger.i(
      'Download success: contentId=$contentId, '
      'size=${fileSizeBytes != null ? '${(fileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB' : 'unknown'}, '
      'duration=${duration?.inSeconds}s',
    );
  }

  /// Record a failed download
  void recordFailure(int contentId, String reason, {String? errorDetails}) {
    _totalDownloads++;
    _failedDownloads++;
    
    _failureReasons[reason] = (_failureReasons[reason] ?? 0) + 1;
    
    _recentDownloads.add(DownloadRecord(
      contentId: contentId,
      success: false,
      timestamp: DateTime.now(),
      failureReason: reason,
      errorDetails: errorDetails,
    ));
    
    _trimRecentDownloads();
    
    _logger.w(
      'Download failed: contentId=$contentId, reason=$reason, '
      'details=$errorDetails',
    );
  }

  /// Record a cancelled download
  void recordCancellation(int contentId) {
    _totalDownloads++;
    _cancelledDownloads++;
    
    _recentDownloads.add(DownloadRecord(
      contentId: contentId,
      success: false,
      timestamp: DateTime.now(),
      cancelled: true,
    ));
    
    _trimRecentDownloads();
    
    _logger.d('Download cancelled: contentId=$contentId');
  }

  /// Trim recent downloads list to max size
  void _trimRecentDownloads() {
    if (_recentDownloads.length > maxRecentDownloads) {
      _recentDownloads.removeRange(0, _recentDownloads.length - maxRecentDownloads);
    }
  }

  /// Get download success rate as percentage
  double getSuccessRate() {
    if (_totalDownloads == 0) return 0.0;
    return (_successfulDownloads / _totalDownloads) * 100;
  }

  /// Get download statistics
  DownloadStats getStats() {
    return DownloadStats(
      total: _totalDownloads,
      successful: _successfulDownloads,
      failed: _failedDownloads,
      cancelled: _cancelledDownloads,
      successRate: getSuccessRate(),
      failureReasons: Map.from(_failureReasons),
    );
  }

  /// Get recent downloads
  List<DownloadRecord> getRecentDownloads({int? limit}) {
    if (limit == null) return List.from(_recentDownloads);
    
    final startIndex = _recentDownloads.length - limit;
    if (startIndex < 0) return List.from(_recentDownloads);
    
    return _recentDownloads.sublist(startIndex);
  }

  /// Clear all metrics
  void clearMetrics() {
    _totalDownloads = 0;
    _successfulDownloads = 0;
    _failedDownloads = 0;
    _cancelledDownloads = 0;
    _failureReasons.clear();
    _recentDownloads.clear();
    
    _logger.d('Download metrics cleared');
  }

  /// Log download statistics
  void logStats() {
    final stats = getStats();
    
    _logger.i('=== Download Statistics ===');
    _logger.i('Total downloads: ${stats.total}');
    _logger.i('Successful: ${stats.successful}');
    _logger.i('Failed: ${stats.failed}');
    _logger.i('Cancelled: ${stats.cancelled}');
    _logger.i('Success rate: ${stats.successRate.toStringAsFixed(2)}%');
    
    if (stats.failureReasons.isNotEmpty) {
      _logger.i('Failure reasons:');
      for (final entry in stats.failureReasons.entries) {
        _logger.i('  ${entry.key}: ${entry.value}');
      }
    }
  }
}

/// Download statistics data class
class DownloadStats {
  final int total;
  final int successful;
  final int failed;
  final int cancelled;
  final double successRate;
  final Map<String, int> failureReasons;

  DownloadStats({
    required this.total,
    required this.successful,
    required this.failed,
    required this.cancelled,
    required this.successRate,
    required this.failureReasons,
  });
}

/// Individual download record
class DownloadRecord {
  final int contentId;
  final bool success;
  final DateTime timestamp;
  final int? fileSizeBytes;
  final Duration? duration;
  final String? failureReason;
  final String? errorDetails;
  final bool cancelled;

  DownloadRecord({
    required this.contentId,
    required this.success,
    required this.timestamp,
    this.fileSizeBytes,
    this.duration,
    this.failureReason,
    this.errorDetails,
    this.cancelled = false,
  });
}
