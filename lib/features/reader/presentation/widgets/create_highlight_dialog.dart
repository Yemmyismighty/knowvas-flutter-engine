import 'package:flutter/material.dart';

import 'highlight_color_picker.dart';

/// Dialog for creating a new highlight
/// Allows user to select color and optionally add a note
class CreateHighlightDialog extends StatefulWidget {
  const CreateHighlightDialog({
    required this.selectedText,
    required this.pageNumber,
    super.key,
  });

  final String selectedText;
  final int pageNumber;

  @override
  State<CreateHighlightDialog> createState() => _CreateHighlightDialogState();
}

class _CreateHighlightDialogState extends State<CreateHighlightDialog> {
  String _selectedColor = '#FFFF00'; // Default yellow

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.highlight,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Highlight',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Selected text preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _parseColor(_selectedColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page ${widget.pageNumber + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.selectedText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Color picker
              HighlightColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedColor);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Parse color string to Color object
  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      final fullHex = hexColor.length == 6 ? 'FF$hexColor' : hexColor;
      return Color(int.parse(fullHex, radix: 16));
    } catch (e) {
      return Colors.yellow;
    }
  }
}

/// Show create highlight dialog
Future<String?> showCreateHighlightDialog(
  BuildContext context, {
  required String selectedText,
  required int pageNumber,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => CreateHighlightDialog(
      selectedText: selectedText,
      pageNumber: pageNumber,
    ),
  );
}
