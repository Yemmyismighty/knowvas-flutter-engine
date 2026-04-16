import 'package:flutter/material.dart';

/// PDF Reader Screen for comics, magazines, and newspapers
/// This is a placeholder that will be implemented with actual PDF rendering
class PdfReaderScreen extends StatefulWidget {
  final int contentId;
  final String contentTitle;
  final String contentType;

  const PdfReaderScreen({
    required this.contentId,
    required this.contentTitle,
    required this.contentType,
    super.key,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contentTitle),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForType(widget.contentType),
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'PDF Reader',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'PDF reader for ${widget.contentType}s is coming soon!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Content ID: ${widget.contentId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'comic':
        return Icons.auto_stories;
      case 'magazine':
        return Icons.article;
      case 'newspaper':
        return Icons.newspaper;
      default:
        return Icons.picture_as_pdf;
    }
  }
}
