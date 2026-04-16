import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Tracks crashes and errors to monitor app stability
class CrashTracker {
  static final CrashTracker _instance = CrashTracker._internal();
  factory CrashTracker() => _instance;
  CrashTracker._internal();

  final Logger _logger = Logger();
  
  int _totalSessions = 0;
  int _crashFreeSessions = 0;
  final List<CrashRecord> _crashes = [];
  final List<ErrorRecord> _errors = [];
  
  static const int maxCrashRecords = 50;
  static const int maxErrorRecords = 100;
  
  bool _currentSessionHasCrash = false;

  /// Initialize crash tracking
  void initialize() {
    // Set up Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details);
    };

    // Set up zone error handler for async errors
    runZonedGuarded(() {
      // App runs in this zone
    }, (error, stackTrace) {
      recordError(error, stackTrace, fatal: true);
    });

    _logger.i('Crash tracker initialized');
  }

  /// Start a new session
  void startSession() {
    _totalSessions++;
    _currentSessionHasCrash = false;
    _logger.d('New session started: $_totalSessions');
  }

  /// End current session
  void endSession() {
    if (!_currentSessionHasCrash) {
      _crashFreeSessions++;
    }
    _logger.d('Session ended. Crash-free: ${!_currentSessionHasCrash}');
  }

  /// Record a Flutter framework error
  void recordFlutterError(FlutterErrorDetails details) {
    _currentSessionHasCrash = true;
    
    final crash = CrashRecord(
      timestamp: DateTime.now(),
      error: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      context: details.context?.toString(),
      library: details.library,
      fatal: details.silent == false,
    );
    
    _crashes.add(crash);
    _trimCrashRecords();
    
    _logger.e(
      'Flutter error recorded: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
    
    // Still call the default error handler
    FlutterError.presentError(details);
  }

  /// Record a general error
  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? context,
  }) {
    if (fatal) {
      _currentSessionHasCrash = true;
      
      final crash = CrashRecord(
        timestamp: DateTime.now(),
        error: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
        fatal: true,
      );
      
      _crashes.add(crash);
      _trimCrashRecords();
      
      _logger.e(
        'Fatal error recorded: $error',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      final errorRecord = ErrorRecord(
        timestamp: DateTime.now(),
        error: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
      );
      
      _errors.add(errorRecord);
      _trimErrorRecords();
      
      _logger.w(
        'Non-fatal error recorded: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Trim crash records to max size
  void _trimCrashRecords() {
    if (_crashes.length > maxCrashRecords) {
      _crashes.removeRange(0, _crashes.length - maxCrashRecords);
    }
  }

  /// Trim error records to max size
  void _trimErrorRecords() {
    if (_errors.length > maxErrorRecords) {
      _errors.removeRange(0, _errors.length - maxErrorRecords);
    }
  }

  /// Get crash-free users percentage
  double getCrashFreePercentage() {
    if (_totalSessions == 0) return 100.0;
    return (_crashFreeSessions / _totalSessions) * 100;
  }

  /// Get crash statistics
  CrashStats getStats() {
    return CrashStats(
      totalSessions: _totalSessions,
      crashFreeSessions: _crashFreeSessions,
      crashFreePercentage: getCrashFreePercentage(),
      totalCrashes: _crashes.length,
      totalErrors: _errors.length,
    );
  }

  /// Get recent crashes
  List<CrashRecord> getRecentCrashes({int? limit}) {
    if (limit == null) return List.from(_crashes);
    
    final startIndex = _crashes.length - limit;
    if (startIndex < 0) return List.from(_crashes);
    
    return _crashes.sublist(startIndex);
  }

  /// Get recent errors
  List<ErrorRecord> getRecentErrors({int? limit}) {
    if (limit == null) return List.from(_errors);
    
    final startIndex = _errors.length - limit;
    if (startIndex < 0) return List.from(_errors);
    
    return _errors.sublist(startIndex);
  }

  /// Clear all crash data
  void clearData() {
    _totalSessions = 0;
    _crashFreeSessions = 0;
    _crashes.clear();
    _errors.clear();
    _currentSessionHasCrash = false;
    
    _logger.d('Crash tracker data cleared');
  }

  /// Log crash statistics
  void logStats() {
    final stats = getStats();
    
    _logger.i('=== Crash Statistics ===');
    _logger.i('Total sessions: ${stats.totalSessions}');
    _logger.i('Crash-free sessions: ${stats.crashFreeSessions}');
    _logger.i('Crash-free percentage: ${stats.crashFreePercentage.toStringAsFixed(2)}%');
    _logger.i('Total crashes: ${stats.totalCrashes}');
    _logger.i('Total errors: ${stats.totalErrors}');
  }
}

/// Crash statistics data class
class CrashStats {
  final int totalSessions;
  final int crashFreeSessions;
  final double crashFreePercentage;
  final int totalCrashes;
  final int totalErrors;

  CrashStats({
    required this.totalSessions,
    required this.crashFreeSessions,
    required this.crashFreePercentage,
    required this.totalCrashes,
    required this.totalErrors,
  });
}

/// Individual crash record
class CrashRecord {
  final DateTime timestamp;
  final String error;
  final String? stackTrace;
  final String? context;
  final String? library;
  final bool fatal;

  CrashRecord({
    required this.timestamp,
    required this.error,
    this.stackTrace,
    this.context,
    this.library,
    required this.fatal,
  });
}

/// Individual error record
class ErrorRecord {
  final DateTime timestamp;
  final String error;
  final String? stackTrace;
  final String? context;

  ErrorRecord({
    required this.timestamp,
    required this.error,
    this.stackTrace,
    this.context,
  });
}
