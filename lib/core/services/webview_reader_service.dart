import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'encrypted_storage_service.dart';

/// Service for managing WebView-based readers
/// Handles communication between Flutter and JavaScript readers
class WebViewReaderService {
  static final WebViewReaderService _instance = WebViewReaderService._internal();
  factory WebViewReaderService() => _instance;
  WebViewReaderService._internal();

  final EncryptedStorageService _storage = EncryptedStorageService();
  
  /// Custom scheme for loading content files
  static const String customScheme = 'knowvas';
  
  /// Handle custom scheme requests
  Future<CustomSchemeResponse?> handleSchemeRequest(
    Uri uri,
    String contentId,
    String contentType,
  ) async {
    try {
      debugPrint('📥 Custom scheme request: ${uri.toString()}');
      
      // Parse the URI
      // Format: knowvas://content/{contentId}/{resource}
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) {
        return null;
      }
      
      // Determine file extension based on content type
      String fileExtension;
      String mimeType;
      
      if (contentType == 'epub' || contentType == 'book') {
        fileExtension = 'epub';
        mimeType = 'application/epub+zip';
      } else {
        fileExtension = 'pdf';
        mimeType = 'application/pdf';
      }
      
      // Load encrypted file
      final data = await _storage.loadEncryptedFile(
        contentId: contentId,
        fileExtension: fileExtension,
      );
      
      if (data == null) {
        debugPrint('❌ File not found for content: $contentId');
        return CustomSchemeResponse(
          data: Uint8List.fromList(utf8.encode('File not found')),
          contentType: 'text/plain',
        );
      }
      
      debugPrint('✅ Serving file: $contentId.$fileExtension (${data.length} bytes)');
      
      return CustomSchemeResponse(
        data: data,
        contentType: mimeType,
      );
    } catch (e) {
      debugPrint('❌ Error handling scheme request: $e');
      return null;
    }
  }
  
  /// Create JavaScript handler for progress tracking
  JavaScriptHandlerCallback createProgressHandler(
    Function(Map<String, dynamic>) onProgress,
  ) {
    return (List<dynamic> args) {
      if (args.isNotEmpty && args[0] is Map) {
        final data = Map<String, dynamic>.from(args[0]);
        onProgress(data);
      }
    };
  }
  
  /// Create JavaScript handler for navigation
  JavaScriptHandlerCallback createNavigationHandler(
    Function(String) onNavigate,
  ) {
    return (List<dynamic> args) {
      if (args.isNotEmpty && args[0] is String) {
        onNavigate(args[0]);
      }
    };
  }
  
  /// Create JavaScript handler for errors
  JavaScriptHandlerCallback createErrorHandler(
    Function(String) onError,
  ) {
    return (List<dynamic> args) {
      if (args.isNotEmpty && args[0] is String) {
        onError(args[0]);
      }
    };
  }
  
  /// Send command to reader
  Future<void> sendCommand(
    InAppWebViewController controller,
    String command,
    Map<String, dynamic>? params,
  ) async {
    try {
      final paramsJson = params != null ? jsonEncode(params) : '{}';
      final script = 'window.readerBridge.handleCommand("$command", $paramsJson)';
      await controller.evaluateJavascript(source: script);
      debugPrint('📤 Sent command to reader: $command');
    } catch (e) {
      debugPrint('❌ Failed to send command: $e');
    }
  }
  
  /// Load content in reader
  Future<void> loadContent(
    InAppWebViewController controller,
    String contentId,
    String contentType,
  ) async {
    final url = '$customScheme://content/$contentId/file';
    await sendCommand(controller, 'loadContent', {
      'url': url,
      'contentId': contentId,
      'contentType': contentType,
    });
  }
  
  /// Navigate to location
  Future<void> navigateToLocation(
    InAppWebViewController controller,
    String location,
  ) async {
    await sendCommand(controller, 'navigateTo', {
      'location': location,
    });
  }
  
  /// Set reader settings
  Future<void> updateSettings(
    InAppWebViewController controller,
    Map<String, dynamic> settings,
  ) async {
    await sendCommand(controller, 'updateSettings', settings);
  }
}
