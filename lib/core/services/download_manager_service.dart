import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'encrypted_storage_service.dart';

/// Download manager for content files
/// Handles downloading and encrypting content for offline reading
class DownloadManagerService {
  static final DownloadManagerService _instance = DownloadManagerService._internal();
  factory DownloadManagerService() => _instance;
  DownloadManagerService._internal();

  final Dio _dio = Dio();
  final EncryptedStorageService _storage = EncryptedStorageService();
  
  // Track active downloads
  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, double> _downloadProgress = {};
  
  /// Download and encrypt content
  Future<bool> downloadContent({
    required String contentId,
    required String contentType,
    required String apiUrl,
    required String authToken,
    Function(double)? onProgress,
  }) async {
    try {
      // Check if already downloading
      if (_activeDownloads.containsKey(contentId)) {
        debugPrint('⚠️ Already downloading: $contentId');
        return false;
      }
      
      // Determine file extension
      final fileExtension = _getFileExtension(contentType);
      
      // Check if already downloaded
      final exists = await _storage.fileExists(
        contentId: contentId,
        fileExtension: fileExtension,
      );
      
      if (exists) {
        debugPrint('✅ Content already downloaded: $contentId');
        return true;
      }
      
      debugPrint('📥 Starting download: $contentId');
      
      // Create cancel token
      final cancelToken = CancelToken();
      _activeDownloads[contentId] = cancelToken;
      _downloadProgress[contentId] = 0.0;
      
      // Download file
      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
          responseType: ResponseType.bytes,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[contentId] = progress;
            onProgress?.call(progress);
            debugPrint('📥 Download progress: ${(progress * 100).toInt()}%');
          }
        },
      );
      
      if (response.statusCode == 200) {
        final data = Uint8List.fromList(response.data);
        debugPrint('✅ Downloaded ${data.length} bytes');
        
        // Encrypt and save
        await _storage.saveEncryptedFile(
          contentId: contentId,
          data: data,
          fileExtension: fileExtension,
        );
        
        debugPrint('✅ Content downloaded and encrypted: $contentId');
        
        // Cleanup
        _activeDownloads.remove(contentId);
        _downloadProgress.remove(contentId);
        
        return true;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      _activeDownloads.remove(contentId);
      _downloadProgress.remove(contentId);
      return false;
    }
  }
  
  /// Cancel download
  Future<void> cancelDownload(String contentId) async {
    final cancelToken = _activeDownloads[contentId];
    if (cancelToken != null) {
      cancelToken.cancel('User cancelled');
      _activeDownloads.remove(contentId);
      _downloadProgress.remove(contentId);
      debugPrint('🚫 Download cancelled: $contentId');
    }
  }
  
  /// Get download progress
  double? getDownloadProgress(String contentId) {
    return _downloadProgress[contentId];
  }
  
  /// Check if downloading
  bool isDownloading(String contentId) {
    return _activeDownloads.containsKey(contentId);
  }
  
  /// Check if downloaded
  Future<bool> isDownloaded({
    required String contentId,
    required String contentType,
  }) async {
    final fileExtension = _getFileExtension(contentType);
    return await _storage.fileExists(
      contentId: contentId,
      fileExtension: fileExtension,
    );
  }
  
  /// Delete downloaded content
  Future<void> deleteDownload({
    required String contentId,
    required String contentType,
  }) async {
    final fileExtension = _getFileExtension(contentType);
    await _storage.deleteEncryptedFile(
      contentId: contentId,
      fileExtension: fileExtension,
    );
    debugPrint('🗑️ Deleted download: $contentId');
  }
  
  /// Get file extension from content type
  String _getFileExtension(String contentType) {
    if (contentType == 'epub' || contentType == 'book') {
      return 'epub';
    }
    return 'pdf';
  }
  
  /// Get download size
  Future<int?> getDownloadSize({
    required String contentId,
    required String contentType,
  }) async {
    final fileExtension = _getFileExtension(contentType);
    return await _storage.getFileSize(
      contentId: contentId,
      fileExtension: fileExtension,
    );
  }
  
  /// Clear all downloads
  Future<void> clearAllDownloads() async {
    // Cancel active downloads
    for (final cancelToken in _activeDownloads.values) {
      cancelToken.cancel('Clearing all downloads');
    }
    _activeDownloads.clear();
    _downloadProgress.clear();
    
    // Delete all files
    await _storage.clearAll();
    debugPrint('🗑️ Cleared all downloads');
  }
}
