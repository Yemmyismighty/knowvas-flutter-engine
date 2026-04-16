import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/reader_dtos.dart';
import '../providers/reader_provider.dart';

/// Reader settings panel displayed as a bottom sheet
/// Allows users to customize reading experience with font, theme, and layout options
class ReaderSettingsPanel extends ConsumerStatefulWidget {
  const ReaderSettingsPanel({super.key});

  @override
  ConsumerState<ReaderSettingsPanel> createState() =>
      _ReaderSettingsPanelState();
}

class _ReaderSettingsPanelState extends ConsumerState<ReaderSettingsPanel> {
  late ReaderPreferences _preferences;

  @override
  void initState() {
    super.initState();
    // Initialize with current preferences
    final readerState = ref.read(readerProvider);
    _preferences = readerState.preferences;
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);
    final contentType = readerState.contentType;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 24),

              // Font size slider (EPUB only)
              if (contentType == 'epub') ...[
                _buildFontSizeSlider(),
                const SizedBox(height: 24),
              ],

              // Font family selector (EPUB only)
              if (contentType == 'epub') ...[
                _buildFontFamilySelector(),
                const SizedBox(height: 24),
              ],

              // Theme selector (all types)
              _buildThemeSelector(contentType),
              const SizedBox(height: 24),

              // Line height control (EPUB only)
              if (contentType == 'epub') ...[
                _buildLineHeightSlider(),
                const SizedBox(height: 24),
              ],

              // Margin control (EPUB only)
              if (contentType == 'epub') ...[
                _buildMarginSlider(),
                const SizedBox(height: 24),
              ],

              // Layout options (EPUB and Comic)
              if (contentType == 'epub' || contentType == 'comic') ...[
                _buildLayoutSelector(contentType),
                const SizedBox(height: 24),
              ],

              // Apply button
              _buildApplyButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'Reader Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    final fontSize = _preferences.fontSize ?? 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Size',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('A', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: fontSize.toDouble(),
                min: 12,
                max: 32,
                divisions: 20,
                label: fontSize.toString(),
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(
                      fontSize: value.round(),
                    );
                  });
                },
              ),
            ),
            Text('A', style: TextStyle(fontSize: 24)),
          ],
        ),
        Center(
          child: Text(
            '${fontSize}px',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector() {
    final fontFamily = _preferences.fontFamily ?? 'serif';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Family',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Serif',
              value: 'serif',
              groupValue: fontFamily,
              onSelected: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(fontFamily: value);
                });
              },
            ),
            _buildChoiceChip(
              label: 'Sans Serif',
              value: 'sans-serif',
              groupValue: fontFamily,
              onSelected: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(fontFamily: value);
                });
              },
            ),
            _buildChoiceChip(
              label: 'Monospace',
              value: 'monospace',
              groupValue: fontFamily,
              onSelected: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(fontFamily: value);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSelector(String? contentType) {
    final theme = _preferences.theme ?? 'light';
    final isEpub = contentType == 'epub';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildThemeChip(
              label: 'Light',
              value: 'light',
              groupValue: theme,
              color: Colors.white,
              textColor: Colors.black,
              onSelected: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(theme: value);
                });
              },
            ),
            if (isEpub)
              _buildThemeChip(
                label: 'Sepia',
                value: 'sepia',
                groupValue: theme,
                color: const Color(0xFFF4ECD8),
                textColor: Colors.black87,
                onSelected: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(theme: value);
                  });
                },
              ),
            _buildThemeChip(
              label: 'Dark',
              value: 'dark',
              groupValue: theme,
              color: const Color(0xFF1E1E1E),
              textColor: Colors.white,
              onSelected: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(theme: value);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineHeightSlider() {
    final lineHeight = _preferences.lineHeight ?? 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Height',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Slider(
          value: lineHeight,
          min: 1.0,
          max: 2.5,
          divisions: 15,
          label: lineHeight.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _preferences = _preferences.copyWith(lineHeight: value);
            });
          },
        ),
        Center(
          child: Text(
            lineHeight.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildMarginSlider() {
    final margin = _preferences.margin ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Margins',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Slider(
          value: margin,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: margin.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _preferences = _preferences.copyWith(margin: value);
            });
          },
        ),
        Center(
          child: Text(
            margin.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutSelector(String? contentType) {
    final layout = _preferences.layout ?? 'single';
    final isEpub = contentType == 'epub';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip(
              label: isEpub ? 'Single Page' : 'Single',
              value: 'single',
              groupValue: layout,
              onSelected: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(layout: value);
                });
              },
            ),
            _buildChoiceChip(
              label: isEpub ? 'Double Page' : 'Double',
              value: 'double',
              groupValue: layout,
              onSelected: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(layout: value);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = value == groupValue;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
    );
  }

  Widget _buildThemeChip({
    required String label,
    required String value,
    required String groupValue,
    required Color color,
    required Color textColor,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = value == groupValue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
      backgroundColor: color,
      selectedColor: color,
      checkmarkColor: textColor,
      labelStyle: TextStyle(
        color: textColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Apply preferences through the reader provider
          await ref.read(readerProvider.notifier).updatePreferences(_preferences);

          if (context.mounted) {
            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings applied'),
                duration: Duration(seconds: 2),
              ),
            );

            // Close the settings panel
            Navigator.of(context).pop();
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Apply Settings'),
      ),
    );
  }
}
