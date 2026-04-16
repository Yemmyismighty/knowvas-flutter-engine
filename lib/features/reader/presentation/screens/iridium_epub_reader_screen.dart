import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iridium_reader_widget/views/viewers/epub_screen.dart';

import '../../../../core/services/encrypted_storage_service.dart';

/// Iridium-based EPUB reader screen
/// Uses Readium 2 technology (same as Thorium) via Iridium Flutter port
class IridiumEpubReaderScreen extends StatefulWidget {
  final String contentId;
  final bool isPreview;

  const IridiumEpubReaderScreen({
    super.key,
    required this.contentId,
    this.isPreview = false,
  });

  @override
  State<IridiumEpubReaderScreen> createState() => _IridiumEpubReaderScreenState();
}

class _IridiumEpubReaderScreenState extends State<IridiumEpubReaderScreen> {
  final EncryptedStorageService _storage = EncryptedStorageService();
  
  bool _isLoading = true;
  String? _error;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    // Set fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadEpubFile();
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadEpubFile() async {
    try {
      // Check if file exists locally
      final exists = await _storage.fileExists(
        contentId: widget.contentId,
        fileExtension: 'epub',
      );
      
      if (!exists && !widget.isPreview) {
        setState(() {
          _error = 'Content not downloaded. Please download it first from the content details page.';
          _isLoading = false;
        });
        return;
      }

      // Get file path for Iridium
      // Iridium needs the actual file path, not encrypted data
      // So we need to decrypt and save to a temporary location
      final data = await _storage.loadEncryptedFile(
        contentId: widget.contentId,
        fileExtension: 'epub',
      );

      if (data == null) {
        setState(() {
          _error = 'Failed to load EPUB file';
          _isLoading = false;
        });
        return;
      }

      // Save decrypted file to temporary location for Iridium
      final tempPath = await _storage.getDecryptedTempPath(
        contentId: widget.contentId,
        fileExtension: 'epub',
      );

      await _storage.saveDecryptedTemp(
        contentId: widget.contentId,
        data: data,
        fileExtension: 'epub',
      );

      setState(() {
        _filePath = tempPath;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading EPUB: $e');
      setState(() {
        _error = 'Failed to load EPUB: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3ECFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading EPUB...',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3ECFF),
        body: SafeArea(
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
                    'Error Loading EPUB',
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
      );
    }

    // Use Iridium's EpubScreen
    return Scaffold(
      body: Stack(
        children: [
          EpubScreen.fromPath(
            filePath: _filePath!,
          ),
          
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
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
          ),
        ],
      ),
    );
  }
}
