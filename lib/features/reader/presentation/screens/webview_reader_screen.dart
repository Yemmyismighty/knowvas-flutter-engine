import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../core/services/encrypted_storage_service.dart';
import '../../../../core/services/webview_reader_service.dart';

/// WebView-based reader screen
/// Supports both EPUB (Thorium Web) and PDF (DearFlip) readers
class WebViewReaderScreen extends StatefulWidget {
  final String contentId;
  final String contentType; // 'epub', 'pdf', 'book', 'comic', 'magazine', 'newspaper'
  final bool isPreview;

  const WebViewReaderScreen({
    super.key,
    required this.contentId,
    required this.contentType,
    this.isPreview = false,
  });

  @override
  State<WebViewReaderScreen> createState() => _WebViewReaderScreenState();
}

class _WebViewReaderScreenState extends State<WebViewReaderScreen> {
  InAppWebViewController? _webViewController;
  final WebViewReaderService _readerService = WebViewReaderService();
  final EncryptedStorageService _storage = EncryptedStorageService();
  
  bool _isLoading = true;
  String? _error;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Set fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECFF),
      body: SafeArea(
        child: Stack(
          children: [
            // WebView
            InAppWebView(
              initialFile: 'assets/reader/reader.html',
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllow: 'camera; microphone',
                iframeAllowFullscreen: true,
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                useHybridComposition: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
              ),
              onWebViewCreated: (controller) async {
                _webViewController = controller;
                
                // Register custom scheme handler
                await controller.webStorage.localStorage.clear();
                
                // Add JavaScript handlers
                controller.addJavaScriptHandler(
                  handlerName: 'onProgress',
                  callback: _readerService.createProgressHandler(_handleProgress),
                );
                
                controller.addJavaScriptHandler(
                  handlerName: 'onNavigate',
                  callback: _readerService.createNavigationHandler(_handleNavigation),
                );
                
                controller.addJavaScriptHandler(
                  handlerName: 'onError',
                  callback: _readerService.createErrorHandler(_handleError),
                );
                
                debugPrint('✅ WebView created and handlers registered');
              },
              onLoadStop: (controller, url) async {
                debugPrint('✅ WebView loaded: $url');
                setState(() => _isLoading = false);
                
                // Initialize reader
                await _initializeReader();
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('🌐 Console: ${consoleMessage.message}');
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                
                // Handle custom scheme
                if (uri?.scheme == WebViewReaderService.customScheme) {
                  debugPrint('📥 Custom scheme request: ${uri.toString()}');
                  
                  // Load encrypted file
                  final fileExtension = _getFileExtension();
                  final data = await _storage.loadEncryptedFile(
                    contentId: widget.contentId,
                    fileExtension: fileExtension,
                  );
                  
                  if (data != null) {
                    // Convert to base64 for WebView
                    final base64Data = base64Encode(data);
                    final mimeType = fileExtension == 'epub' 
                        ? 'application/epub+zip' 
                        : 'application/pdf';
                    
                    // Create data URL
                    final dataUrl = 'data:$mimeType;base64,$base64Data';
                    
                    // Inject into reader
                    await controller.evaluateJavascript(
                      source: '''
                        window.readerBridge.handleCommand('loadContent', {
                          url: '$dataUrl',
                          contentId: '${widget.contentId}',
                          contentType: '${widget.contentType}'
                        });
                      ''',
                    );
                  } else {
                    debugPrint('❌ File not found');
                    setState(() {
                      _error = 'Content file not found. Please download it first.';
                    });
                  }
                  
                  return NavigationActionPolicy.CANCEL;
                }
                
                return NavigationActionPolicy.ALLOW;
              },
            ),
            
            // Loading indicator
            if (_isLoading)
              Container(
                color: const Color(0xFFF3ECFF),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading reader...',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                      if (_progress > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            // Error message
            if (_error != null)
              Container(
                color: const Color(0xFFF3ECFF),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFF7A2FC4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Content',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9D4EDD),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeReader() async {
    try {
      // Check if file exists locally
      final fileExtension = _getFileExtension();
      final exists = await _storage.fileExists(
        contentId: widget.contentId,
        fileExtension: fileExtension,
      );
      
      if (!exists && !widget.isPreview) {
        // File not downloaded, need to download first
        setState(() {
          _error = 'Content not downloaded. Please download it first from the content details page.';
        });
        return;
      }
      
      // Load content in reader
      if (_webViewController != null) {
        await _readerService.loadContent(
          _webViewController!,
          widget.contentId,
          widget.contentType,
        );
      }
    } catch (e) {
      debugPrint('❌ Error initializing reader: $e');
      setState(() {
        _error = 'Failed to initialize reader: $e';
      });
    }
  }

  String _getFileExtension() {
    if (widget.contentType == 'epub' || widget.contentType == 'book') {
      return 'epub';
    }
    return 'pdf';
  }

  void _handleProgress(Map<String, dynamic> data) {
    debugPrint('📊 Progress update: $data');
    // TODO: Save progress to backend
  }

  void _handleNavigation(String location) {
    debugPrint('🧭 Navigation: $location');
    // TODO: Track navigation for analytics
  }

  void _handleError(String error) {
    debugPrint('❌ Reader error: $error');
    setState(() {
      _error = error;
    });
  }
}
