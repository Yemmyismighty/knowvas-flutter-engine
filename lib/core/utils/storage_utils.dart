import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Storage utilities for checking available space
class StorageUtils {
  /// Minimum required storage in bytes (100 MB)
  static const int minRequiredStorage = 100 * 1024 * 1024;
  
  /// Low storage warning threshold in bytes (500 MB)
  static const int lowStorageThreshold = 500 * 1024 * 1024;

  /// Get available storage space in bytes
  static Future<int> getAvailableStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();
      
      // On Android/iOS, we can check the free space
      if (Platform.isAndroid || Platform.isIOS) {
        // Use platform-specific methods if available
        // For now, return a large number as placeholder
        // In production, use platform channels to get actual free space
        return 1024 * 1024 * 1024; // 1 GB placeholder
      }
      
      return 1024 * 1024 * 1024; // 1 GB placeholder
    } catch (e) {
      return 0;
    }
  }

  /// Check if there's enough storage for a download
  static Future<bool> hasEnoughStorage(int requiredBytes) async {
    final available = await getAvailableStorage();
    return available >= (requiredBytes + minRequiredStorage);
  }

  /// Check if storage is low
  static Future<bool> isStorageLow() async {
    final available = await getAvailableStorage();
    return available < lowStorageThreshold;
  }

  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get storage info as a map
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final available = await getAvailableStorage();
    final isLow = await isStorageLow();
    
    return {
      'available': available,
      'availableFormatted': formatBytes(available),
      'isLow': isLow,
    };
  }
}
