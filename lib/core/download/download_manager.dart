import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database.dart';
import '../errors/exceptions.dart';
import '../security/encryption_service.dart';

/// Download status enum
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Download progress model
class DownloadProgress {
  final int contentId;
  final double progress; // 0.0 to 1.0
  final int bytesDownloaded;
  final int totalBytes;
  final DownloadStatus status;
  final String? error;

  const DownloadProgress({
    required this.contentId,
    required this.progress,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.status,
    this.error,
  });

  DownloadProgress copyWith({
    int? contentId,
    double? progress,
    int? bytesDownloaded,
    int? totalBytes,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadProgress(
      contentId: contentId ?? this.contentId,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

/// Downloaded content model
class DownloadedContent {
  final int contentId;
  final String userId;
  final String filePath;
  final String encryptedPath;
  final int fileSize;
  final DateTime downloadDate;
  final String quality;
  final String hash;

  const DownloadedContent({
    required this.contentId,
    required this.userId,
    required this.filePath,
    required this.encryptedPath,
    required this.fileSize,
    required this.downloadDate,
    required this.quality,
    required this.hash,
  });

  Map<String, dynamic> toMap() {
    return {
      'content_id': contentId,
      'user_id': userId,
      'file_path': filePath,
      'encrypted_path': encryptedPath,
      'file_size': fileSize,
      'download_date': downloadDate.millisecondsSinceEpoch,
      'quality': quality,
      'hash': hash,
    };
  }

  factory DownloadedContent.fromMap(Map<String, dynamic> map) {
    return DownloadedContent(
      contentId: map['content_id'] as int,
      userId: map['user_id'] as String,
      filePath: map['file_path'] as String,
      encryptedPath: map['encrypted_path'] as String,
      fileSize: map['file_size'] as int,
      downloadDate: DateTime.fromMillisecondsSinceEpoch(map['download_date'] as int),
      quality: map['quality'] as String,
      hash: map['hash'] as String,
    );
  }
}

/// Download queue item for managing downloads
class _DownloadQueueItem {
  final int contentId;
  final String signedUrl;
  final String userId;
  final String quality;
  final String? expectedHash;
  final StreamController<DownloadProgress> controller;
  CancelToken? cancelToken;
  int bytesDownloaded;
  String? tempFilePath;

  _DownloadQueueItem({
    required this.contentId,
    required this.signedUrl,
    required this.userId,
    required this.quality,
    this.expectedHash,
    required this.controller,
    this.cancelToken,
    this.bytesDownloaded = 0,
    this.tempFilePath,
  });
}

/// Download manager for handling content downloads with encryption and queue management
class DownloadManager {
  DownloadManager({
    required Dio dio,
    required EncryptionService encryptionService,
    required KnowvasDatabase database,
    Logger? logger,
  })  : _dio = dio,
        _encryptionService = encryptionService,
        _database = database,
        _logger = logger ?? Logger();

  final Dio _dio;
  final EncryptionService _encryptionService;
  final KnowvasDatabase _database;
  final Logger _logger;

  final Map<int, _DownloadQueueItem> _activeDownloads = {};
  final List<_DownloadQueueItem> _downloadQueue = [];
  bool _isProcessingQueue = false;
  static const int _maxConcurrentDownloads = 3;
  static const int _maxRetries = 3;

  /// Download content with progress tracking, encryption, and queue management
  Future<void> downloadContent({
    required int contentId,
    required String signedUrl,
    required String userId,
    required String quality,
    String? expectedHash,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Check if already downloaded
      final existing = await _getDownloadedContent(contentId, userId);
      if (existing != null) {
        _logger.i('Content $contentId already downloaded');
        return;
      }

      // Check if already in queue or downloading
      if (_activeDownloads.containsKey(contentId) ||
          _downloadQueue.any((item) => item.contentId == contentId)) {
        _logger.w('Content $contentId already in download queue');
        return;
      }

      // Create progress controller
      final controller = StreamController<DownloadProgress>.broadcast();

      // Create queue item
      final queueItem = _DownloadQueueItem(
        contentId: contentId,
        signedUrl: signedUrl,
        userId: userId,
        quality: quality,
        expectedHash: expectedHash,
        controller: controller,
      );

      // Add to queue
      _downloadQueue.add(queueItem);

      // Emit queued status
      controller.add(DownloadProgress(
        contentId: contentId,
        progress: 0.0,
        bytesDownloaded: 0,
        totalBytes: 0,
        status: DownloadStatus.queued,
      ));

      // Process queue
      _processQueue();

      // Listen to progress if callback provided
      if (onProgress != null) {
        controller.stream.listen((progress) {
          if (progress.status == DownloadStatus.downloading) {
            onProgress(progress.progress);
          }
        });
      }
    } catch (e) {
      _logger.e('Error initiating download for content $contentId: $e');
      throw CacheException(
        'Failed to initiate download: $e',
        code: 'DOWNLOAD_INIT_ERROR',
      );
    }
  }

  /// Process download queue
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_downloadQueue.isNotEmpty &&
          _activeDownloads.length < _maxConcurrentDownloads) {
        final item = _downloadQueue.removeAt(0);
        _activeDownloads[item.contentId] = item;
        _startDownload(item);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Start downloading a queue item
  Future<void> _startDownload(_DownloadQueueItem item) async {
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        await _executeDownload(item);
        return;
      } catch (e) {
        retryCount++;
        _logger.w(
          'Download attempt $retryCount failed for content ${item.contentId}: $e',
        );

        if (retryCount >= _maxRetries) {
          item.controller.add(DownloadProgress(
            contentId: item.contentId,
            progress: 0.0,
            bytesDownloaded: 0,
            totalBytes: 0,
            status: DownloadStatus.failed,
            error: 'Download failed after $_maxRetries attempts: $e',
          ));
          _cleanupDownload(item.contentId);
          return;
        }

        // Exponential backoff
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  /// Execute the actual download
  Future<void> _executeDownload(_DownloadQueueItem item) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = path.join(
        tempDir.path,
        'download_${item.contentId}_${DateTime.now().millisecondsSinceEpoch}.tmp',
      );
      item.tempFilePath = tempFilePath;

      // Create cancel token
      final cancelToken = CancelToken();
      item.cancelToken = cancelToken;

      // Download file
      await _dio.download(
        item.signedUrl,
        tempFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            item.bytesDownloaded = received;

            item.controller.add(DownloadProgress(
              contentId: item.contentId,
              progress: progress,
              bytesDownloaded: received,
              totalBytes: total,
              status: DownloadStatus.downloading,
            ));
          }
        },
      );

      // Verify file integrity if hash provided
      if (item.expectedHash != null) {
        final isValid = await _verifyFileIntegrity(
          tempFilePath,
          item.expectedHash!,
        );
        if (!isValid) {
          throw const CacheException(
            'File integrity verification failed',
            code: 'INTEGRITY_CHECK_FAILED',
          );
        }
      }

      // Read file for encryption
      final file = File(tempFilePath);
      final fileData = await file.readAsBytes();
      final fileSize = fileData.length;

      // Calculate hash if not provided
      final fileHash = item.expectedHash ?? _calculateHash(fileData);

      // Encrypt file
      final encryptedData = await _encryptionService.encryptFile(
        fileData,
        item.userId,
      );

      // Save encrypted file
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(path.join(appDir.path, 'downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final encryptedFilePath = path.join(
        downloadsDir.path,
        'content_${item.contentId}.enc',
      );
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encryptedData);

      // Store metadata in database
      await _saveDownloadMetadata(
        contentId: item.contentId,
        userId: item.userId,
        filePath: tempFilePath,
        encryptedPath: encryptedFilePath,
        fileSize: fileSize,
        quality: item.quality,
        hash: fileHash,
      );

      // Update library item as downloaded
      await _updateLibraryItemDownloadStatus(item.contentId, item.userId, true);

      // Delete temp file
      if (await file.exists()) {
        await file.delete();
      }

      // Emit completed status
      item.controller.add(DownloadProgress(
        contentId: item.contentId,
        progress: 1.0,
        bytesDownloaded: fileSize,
        totalBytes: fileSize,
        status: DownloadStatus.completed,
      ));

      _logger.i('Download completed for content ${item.contentId}');
      _cleanupDownload(item.contentId);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        item.controller.add(DownloadProgress(
          contentId: item.contentId,
          progress: 0.0,
          bytesDownloaded: 0,
          totalBytes: 0,
          status: DownloadStatus.cancelled,
        ));
        _cleanupDownload(item.contentId);
      } else {
        rethrow;
      }
    }
  }

  /// Verify file integrity using SHA256 hash
  Future<bool> _verifyFileIntegrity(String filePath, String expectedHash) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final actualHash = _calculateHash(bytes);
      return actualHash.toLowerCase() == expectedHash.toLowerCase();
    } catch (e) {
      _logger.e('Error verifying file integrity: $e');
      return false;
    }
  }

  /// Calculate SHA256 hash of data
  String _calculateHash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Save download metadata to database
  Future<void> _saveDownloadMetadata({
    required int contentId,
    required String userId,
    required String filePath,
    required String encryptedPath,
    required int fileSize,
    required String quality,
    required String hash,
  }) async {
    final db = await _database.database;
    await db.insert(
      'downloaded_files',
      {
        'content_id': contentId,
        'user_id': userId,
        'file_path': filePath,
        'encrypted_path': encryptedPath,
        'file_size': fileSize,
        'download_date': DateTime.now().millisecondsSinceEpoch,
        'quality': quality,
        'hash': hash,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update library item download status
  Future<void> _updateLibraryItemDownloadStatus(
    int contentId,
    String userId,
    bool isDownloaded,
  ) async {
    final db = await _database.database;
    await db.update(
      'library_items',
      {'is_downloaded': isDownloaded ? 1 : 0},
      where: 'content_id = ? AND user_id = ?',
      whereArgs: [contentId, userId],
    );
  }

  /// Get downloaded content metadata
  Future<DownloadedContent?> _getDownloadedContent(
    int contentId,
    String userId,
  ) async {
    final db = await _database.database;
    final results = await db.query(
      'downloaded_files',
      where: 'content_id = ? AND user_id = ?',
      whereArgs: [contentId, userId],
    );

    if (results.isEmpty) return null;
    return DownloadedContent.fromMap(results.first);
  }

  /// Pause download
  Future<void> pauseDownload(int contentId) async {
    final item = _activeDownloads[contentId];
    if (item != null && item.cancelToken != null) {
      item.cancelToken!.cancel('Download paused by user');
      item.controller.add(DownloadProgress(
        contentId: contentId,
        progress: item.bytesDownloaded > 0 ? item.bytesDownloaded / 1.0 : 0.0,
        bytesDownloaded: item.bytesDownloaded,
        totalBytes: 0,
        status: DownloadStatus.paused,
      ));
      _logger.i('Download paused for content $contentId');
    }
  }

  /// Resume download
  Future<void> resumeDownload(int contentId) async {
    // Find paused download in active downloads
    final item = _activeDownloads[contentId];
    if (item != null && item.tempFilePath != null) {
      // Re-add to queue for resumption
      _downloadQueue.insert(0, item);
      _activeDownloads.remove(contentId);
      _processQueue();
      _logger.i('Download resumed for content $contentId');
    } else {
      throw CacheException(
        'Cannot resume download: content $contentId not found in paused downloads',
        code: 'RESUME_ERROR',
      );
    }
  }

  /// Cancel download
  Future<void> cancelDownload(int contentId) async {
    // Cancel active download
    final item = _activeDownloads[contentId];
    if (item != null) {
      if (item.cancelToken != null && !item.cancelToken!.isCancelled) {
        item.cancelToken!.cancel('Download cancelled by user');
      }

      // Delete temp file if exists
      if (item.tempFilePath != null) {
        final tempFile = File(item.tempFilePath!);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      _cleanupDownload(contentId);
      _logger.i('Download cancelled for content $contentId');
    }

    // Remove from queue if queued
    _downloadQueue.removeWhere((item) => item.contentId == contentId);
  }

  /// Delete downloaded content
  Future<void> deleteDownload(int contentId, String userId) async {
    try {
      // Get download metadata
      final downloaded = await _getDownloadedContent(contentId, userId);
      if (downloaded == null) {
        _logger.w('Content $contentId not found in downloads');
        return;
      }

      // Delete encrypted file
      final encryptedFile = File(downloaded.encryptedPath);
      if (await encryptedFile.exists()) {
        await encryptedFile.delete();
      }

      // Delete from database
      final db = await _database.database;
      await db.delete(
        'downloaded_files',
        where: 'content_id = ? AND user_id = ?',
        whereArgs: [contentId, userId],
      );

      // Update library item status
      await _updateLibraryItemDownloadStatus(contentId, userId, false);

      _logger.i('Download deleted for content $contentId');
    } catch (e) {
      _logger.e('Error deleting download for content $contentId: $e');
      throw CacheException(
        'Failed to delete download: $e',
        code: 'DELETE_ERROR',
      );
    }
  }

  /// Watch download progress for a specific content
  Stream<DownloadProgress>? watchDownload(int contentId) {
    final item = _activeDownloads[contentId];
    return item?.controller.stream;
  }

  /// Get all downloaded content for a user
  Future<List<DownloadedContent>> getDownloadedContent(String userId) async {
    try {
      final db = await _database.database;
      final results = await db.query(
        'downloaded_files',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'download_date DESC',
      );

      return results.map((map) => DownloadedContent.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Error getting downloaded content: $e');
      throw CacheException(
        'Failed to get downloaded content: $e',
        code: 'QUERY_ERROR',
      );
    }
  }

  /// Get decrypted file path for reading
  Future<String> getDecryptedFilePath(int contentId, String userId) async {
    try {
      final downloaded = await _getDownloadedContent(contentId, userId);
      if (downloaded == null) {
        throw CacheException(
          'Content $contentId not found in downloads',
          code: 'NOT_FOUND',
        );
      }

      // Read encrypted file
      final encryptedFile = File(downloaded.encryptedPath);
      if (!await encryptedFile.exists()) {
        throw CacheException(
          'Encrypted file not found for content $contentId',
          code: 'FILE_NOT_FOUND',
        );
      }

      final encryptedData = await encryptedFile.readAsBytes();

      // Decrypt file
      final decryptedData = await _encryptionService.decryptFile(
        encryptedData,
        userId,
      );

      // Save to temp location
      final tempDir = await getTemporaryDirectory();
      final decryptedPath = path.join(
        tempDir.path,
        'decrypted_${contentId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final decryptedFile = File(decryptedPath);
      await decryptedFile.writeAsBytes(decryptedData);

      return decryptedPath;
    } catch (e) {
      _logger.e('Error getting decrypted file path: $e');
      throw CacheException(
        'Failed to decrypt file: $e',
        code: 'DECRYPTION_ERROR',
      );
    }
  }

  /// Clean up download resources
  void _cleanupDownload(int contentId) {
    final item = _activeDownloads.remove(contentId);
    item?.controller.close();

    // Process next item in queue
    _processQueue();
  }

  /// Dispose all resources
  void dispose() {
    for (final item in _activeDownloads.values) {
      item.controller.close();
    }
    _activeDownloads.clear();
    _downloadQueue.clear();
    _logger.i('DownloadManager disposed');
  }
}
