import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/platform/reader_channel.dart';
import '../../../../core/platform/reader_dtos.dart';

/// Test screen for opening local epub files
/// 
/// This screen provides two ways to test the epub reader:
/// 1. Pick an epub file from device storage
/// 2. Use a test epub file from assets (if available)
class ReaderTestScreen extends StatefulWidget {
  const ReaderTestScreen({super.key});

  @override
  State<ReaderTestScreen> createState() => _ReaderTestScreenState();
}

class _ReaderTestScreenState extends State<ReaderTestScreen> {
  final ReaderChannel _readerChannel = ReaderChannel();
  String? _selectedFilePath;
  String _statusMessage = 'No file selected';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Reader Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test EPUB Reader',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select an EPUB file from your device to test the reader functionality.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // File selection button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickEpubFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick EPUB File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Selected file info
            if (_selectedFilePath != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'File Selected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilePath!.split('/').last,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Open reader button
            ElevatedButton.icon(
              onPressed: (_selectedFilePath != null && !_isLoading)
                  ? _openReader
                  : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.menu_book),
              label: Text(_isLoading ? 'Opening...' : 'Open in Reader'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Status message
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions for adding test files
            Expanded(
              child: Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            Text(
                              'How to Test',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '1. Download a free EPUB file from:\n'
                          '   • Project Gutenberg (gutenberg.org)\n'
                          '   • Standard Ebooks (standardebooks.org)\n'
                          '   • Internet Archive (archive.org)\n\n'
                          '2. Transfer the EPUB to your device\n\n'
                          '3. Click "Pick EPUB File" and select it\n\n'
                          '4. Click "Open in Reader" to test\n\n'
                          'Alternative: Place test EPUB files in:\n'
                          'assets/test_books/ and add to pubspec.yaml',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[900],
                            height: 1.5,
                          ),
                        ),
                      ],
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

  /// Picks an EPUB file from device storage
  Future<void> _pickEpubFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _statusMessage = 'File selected: ${result.files.single.name}';
        });
      } else {
        setState(() {
          _statusMessage = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error picking file: $e';
      });
    }
  }

  /// Opens the selected EPUB file in the reader
  Future<void> _openReader() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening reader...';
    });

    try {
      final request = OpenReaderRequest(
        contentId: 0, // Test content ID
        type: 'epub',
        fileUrl: _selectedFilePath!,
        token: '', // Empty token for local files
        sessionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await _readerChannel.openReader(request);

      setState(() {
        _isLoading = false;
        if (response.isSuccess) {
          _statusMessage = 'Reader opened successfully!';
        } else {
          _statusMessage =
              'Error: ${response.errorMessage ?? 'Unknown error'}';
        }
      });

      if (response.isSuccess) {
        // Show success dialog
        if (mounted) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Exception: $e';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: const Text(
          'The EPUB reader has been opened successfully. '
          'The native reader should now be displaying your book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
