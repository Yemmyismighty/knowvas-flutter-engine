import 'package:logger/logger.dart';

/// Tracks reader-specific performance metrics
class ReaderMetrics {
  static final ReaderMetrics _instance = ReaderMetrics._internal();
  factory ReaderMetrics() => _instance;
  ReaderMetrics._internal();

  final Logger _logger = Logger();
  
  final Map<String, DateTime> _readerOpenStartTimes = {};
  final List<ReaderOpenRecord> _readerOpens = [];
  final List<PageTurnRecord> _pageTurns = [];
  
  static const int maxReaderOpenRecords = 100;
  static const int maxPageTurnRecords = 500;
  
  // Performance thresholds
  static const int readerOpenThresholdMs = 4000;
  static const int pageTurnThresholdMs = 100;

  /// Start tracking reader open time
  void startReaderOpen(int contentId, String contentType) {
    final key = '${contentId}_$contentType';
    _readerOpenStartTimes[key] = DateTime.now();
    _logger.d('Reader open started: contentId=$contentId, type=$contentType');
  }

  /// Stop tracking reader open time
  void stopReaderOpen(int contentId, String contentType, {bool success = true}) {
    final key = '${contentId}_$contentType';
    final startTime = _readerOpenStartTimes.remove(key);
    
    if (startTime == null) {
      _logger.w('No start time found for reader open: $key');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    
    final record = ReaderOpenRecord(
      contentId: contentId,
      contentType: contentType,
      timestamp: DateTime.now(),
      duration: duration,
      success: success,
    );
    
    _readerOpens.add(record);
    _trimReaderOpenRecords();
    
    final durationMs = duration.inMilliseconds;
    
    if (durationMs > readerOpenThresholdMs) {
      _logger.w(
        'Reader open slow: contentId=$contentId, type=$contentType, '
        'duration=${durationMs}ms (threshold: ${readerOpenThresholdMs}ms)',
      );
    } else {
      _logger.i(
        'Reader opened: contentId=$contentId, type=$contentType, '
        'duration=${durationMs}ms',
      );
    }
  }

  /// Record a page turn event
  void recordPageTurn(
    int contentId,
    String contentType,
    int fromPage,
    int toPage,
    Duration latency,
  ) {
    final record = PageTurnRecord(
      contentId: contentId,
      contentType: contentType,
      timestamp: DateTime.now(),
      fromPage: fromPage,
      toPage: toPage,
      latency: latency,
    );
    
    _pageTurns.add(record);
    _trimPageTurnRecords();
    
    final latencyMs = latency.inMilliseconds;
    
    if (latencyMs > pageTurnThresholdMs) {
      _logger.w(
        'Page turn slow: contentId=$contentId, '
        'page $fromPage→$toPage, latency=${latencyMs}ms',
      );
    }
  }

  /// Trim reader open records to max size
  void _trimReaderOpenRecords() {
    if (_readerOpens.length > maxReaderOpenRecords) {
      _readerOpens.removeRange(0, _readerOpens.length - maxReaderOpenRecords);
    }
  }

  /// Trim page turn records to max size
  void _trimPageTurnRecords() {
    if (_pageTurns.length > maxPageTurnRecords) {
      _pageTurns.removeRange(0, _pageTurns.length - maxPageTurnRecords);
    }
  }

  /// Get average reader open time
  Duration? getAverageReaderOpenTime({String? contentType}) {
    final records = contentType != null
        ? _readerOpens.where((r) => r.contentType == contentType && r.success).toList()
        : _readerOpens.where((r) => r.success).toList();
    
    if (records.isEmpty) return null;
    
    final totalMs = records.fold<int>(
      0,
      (sum, record) => sum + record.duration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ records.length);
  }

  /// Get average page turn latency
  Duration? getAveragePageTurnLatency({String? contentType}) {
    final records = contentType != null
        ? _pageTurns.where((r) => r.contentType == contentType).toList()
        : _pageTurns;
    
    if (records.isEmpty) return null;
    
    final totalMs = records.fold<int>(
      0,
      (sum, record) => sum + record.latency.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ records.length);
  }

  /// Get reader statistics
  ReaderStats getStats() {
    final successfulOpens = _readerOpens.where((r) => r.success).length;
    final failedOpens = _readerOpens.where((r) => !r.success).length;
    
    final epubAvg = getAverageReaderOpenTime(contentType: 'epub');
    final pdfAvg = getAverageReaderOpenTime(contentType: 'pdf');
    final comicAvg = getAverageReaderOpenTime(contentType: 'comic');
    
    final pageTurnAvg = getAveragePageTurnLatency();
    
    return ReaderStats(
      totalReaderOpens: _readerOpens.length,
      successfulOpens: successfulOpens,
      failedOpens: failedOpens,
      totalPageTurns: _pageTurns.length,
      averageReaderOpenTimeMs: getAverageReaderOpenTime()?.inMilliseconds,
      averageEpubOpenTimeMs: epubAvg?.inMilliseconds,
      averagePdfOpenTimeMs: pdfAvg?.inMilliseconds,
      averageComicOpenTimeMs: comicAvg?.inMilliseconds,
      averagePageTurnLatencyMs: pageTurnAvg?.inMilliseconds,
    );
  }

  /// Get recent reader opens
  List<ReaderOpenRecord> getRecentReaderOpens({int? limit}) {
    if (limit == null) return List.from(_readerOpens);
    
    final startIndex = _readerOpens.length - limit;
    if (startIndex < 0) return List.from(_readerOpens);
    
    return _readerOpens.sublist(startIndex);
  }

  /// Get recent page turns
  List<PageTurnRecord> getRecentPageTurns({int? limit}) {
    if (limit == null) return List.from(_pageTurns);
    
    final startIndex = _pageTurns.length - limit;
    if (startIndex < 0) return List.from(_pageTurns);
    
    return _pageTurns.sublist(startIndex);
  }

  /// Clear all metrics
  void clearMetrics() {
    _readerOpenStartTimes.clear();
    _readerOpens.clear();
    _pageTurns.clear();
    
    _logger.d('Reader metrics cleared');
  }

  /// Log reader statistics
  void logStats() {
    final stats = getStats();
    
    _logger.i('=== Reader Performance Statistics ===');
    _logger.i('Total reader opens: ${stats.totalReaderOpens}');
    _logger.i('Successful opens: ${stats.successfulOpens}');
    _logger.i('Failed opens: ${stats.failedOpens}');
    _logger.i('Average open time: ${stats.averageReaderOpenTimeMs}ms');
    
    if (stats.averageEpubOpenTimeMs != null) {
      _logger.i('  EPUB average: ${stats.averageEpubOpenTimeMs}ms');
    }
    if (stats.averagePdfOpenTimeMs != null) {
      _logger.i('  PDF average: ${stats.averagePdfOpenTimeMs}ms');
    }
    if (stats.averageComicOpenTimeMs != null) {
      _logger.i('  Comic average: ${stats.averageComicOpenTimeMs}ms');
    }
    
    _logger.i('Total page turns: ${stats.totalPageTurns}');
    if (stats.averagePageTurnLatencyMs != null) {
      _logger.i('Average page turn latency: ${stats.averagePageTurnLatencyMs}ms');
    }
  }
}

/// Reader statistics data class
class ReaderStats {
  final int totalReaderOpens;
  final int successfulOpens;
  final int failedOpens;
  final int totalPageTurns;
  final int? averageReaderOpenTimeMs;
  final int? averageEpubOpenTimeMs;
  final int? averagePdfOpenTimeMs;
  final int? averageComicOpenTimeMs;
  final int? averagePageTurnLatencyMs;

  ReaderStats({
    required this.totalReaderOpens,
    required this.successfulOpens,
    required this.failedOpens,
    required this.totalPageTurns,
    this.averageReaderOpenTimeMs,
    this.averageEpubOpenTimeMs,
    this.averagePdfOpenTimeMs,
    this.averageComicOpenTimeMs,
    this.averagePageTurnLatencyMs,
  });
}

/// Reader open record
class ReaderOpenRecord {
  final int contentId;
  final String contentType;
  final DateTime timestamp;
  final Duration duration;
  final bool success;

  ReaderOpenRecord({
    required this.contentId,
    required this.contentType,
    required this.timestamp,
    required this.duration,
    required this.success,
  });
}

/// Page turn record
class PageTurnRecord {
  final int contentId;
  final String contentType;
  final DateTime timestamp;
  final int fromPage;
  final int toPage;
  final Duration latency;

  PageTurnRecord({
    required this.contentId,
    required this.contentType,
    required this.timestamp,
    required this.fromPage,
    required this.toPage,
    required this.latency,
  });
}
