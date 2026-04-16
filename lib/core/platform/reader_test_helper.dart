import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'reader_channel.dart';
import 'reader_dtos.dart';

/// Helper class for testing the epub reader with local files
/// 
/// This class provides utilities to:
/// - Copy test epub files from assets to local storage
/// - Open the reader with local files
/// - Generate test session IDs
class ReaderTestHelper {
  final ReaderChannel _readerChannel = ReaderChannel();

  /// Copies an epub file from assets to local storage
  /// 
  /// [assetPath] - Path to the epub file in assets (e.g., 'assets/test_books/sample.epub')
  /// 
  /// Returns the local file path where the epub was copied
  Future<String> copyEpubFromAssets(String assetPath) async {
    // Load the asset
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List();

    // Get the app's documents directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    
    // Extract filename from asset path
    final String filename = assetPath.split('/').last;
    
    // Create the local file path
    final String localPath = '${appDocDir.path}/$filename';
    final File localFile = File(localPath);

    // Write the bytes to the local file
    await localFile.writeAsBytes(bytes);

    return localPath;
  }

  /// Opens an epub file in the reader
  /// 
  /// [localFilePath] - Path to the local epub file
  /// [contentId] - Optional content ID (defaults to 0 for testing)
  /// 
  /// Returns a [ReaderResponse] indicating success or failure
  Future<ReaderResponse> openLocalEpub(
    String localFilePath, {
    int contentId = 0,
  }) async {
    final request = OpenReaderRequest(
      contentId: contentId,
      type: 'epub',
      fileUrl: localFilePath,
      token: '', // Empty token for local files
      sessionId: _generateSessionId(),
    );

    return await _readerChannel.openReader(request);
  }

  /// Opens an epub file from assets
  /// 
  /// This is a convenience method that combines copying from assets
  /// and opening the reader in one call
  /// 
  /// [assetPath] - Path to the epub file in assets
  /// [contentId] - Optional content ID (defaults to 0 for testing)
  Future<ReaderResponse> openEpubFromAssets(
    String assetPath, {
    int contentId = 0,
  }) async {
    final localPath = await copyEpubFromAssets(assetPath);
    return await openLocalEpub(localPath, contentId: contentId);
  }

  /// Generates a unique session ID for testing
  String _generateSessionId() {
    return 'test_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Checks if a local epub file exists
  Future<bool> epubFileExists(String localFilePath) async {
    final file = File(localFilePath);
    return await file.exists();
  }

  /// Deletes a local epub file (useful for cleanup in tests)
  Future<void> deleteLocalEpub(String localFilePath) async {
    final file = File(localFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
