import 'package:flutter/material.dart';

/// Color picker for highlight colors
/// Displays a horizontal list of predefined colors
class HighlightColorPicker extends StatelessWidget {
  const HighlightColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
    super.key,
  });

  final String selectedColor;
  final void Function(String color) onColorSelected;

  /// Predefined highlight colors
  static const List<Map<String, dynamic>> highlightColors = [
    {'name': 'Yellow', 'hex': '#FFFF00', 'color': Colors.yellow},
    {'name': 'Green', 'hex': '#00FF00', 'color': Colors.green},
    {'name': 'Blue', 'hex': '#00BFFF', 'color': Colors.lightBlue},
    {'name': 'Pink', 'hex': '#FF69B4', 'color': Colors.pink},
    {'name': 'Orange', 'hex': '#FFA500', 'color': Colors.orange},
    {'name': 'Purple', 'hex': '#9370DB', 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Highlight Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: highlightColors.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final colorData = highlightColors[index];
                final isSelected = selectedColor == colorData['hex'];

                return _buildColorOption(
                  context,
                  colorData['name'] as String,
                  colorData['hex'] as String,
                  colorData['color'] as Color,
                  isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual color option
  Widget _buildColorOption(
    BuildContext context,
    String name,
    String hex,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onColorSelected(hex),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 24,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
