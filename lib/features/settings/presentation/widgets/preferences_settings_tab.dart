import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/features/settings/presentation/providers/preferences_provider.dart';

class PreferencesSettingsTab extends ConsumerWidget {
  const PreferencesSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesState = ref.watch(preferencesProvider);
    final preferences = preferencesState.preferences;

    if (preferencesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appearance Card
          _buildCard(
            'Appearance',
            Icons.palette,
            const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
            [
              _buildDropdownTile(
                context,
                ref,
                'Theme',
                'Choose your preferred theme',
                preferences.theme,
                [
                  ('system', 'System Default'),
                  ('light', 'Light'),
                  ('dark', 'Dark'),
                ],
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(theme: value),
                      );
                },
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                'Reduce Motion',
                'Minimize animations and transitions',
                preferences.reduceMotion,
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(reduceMotion: value),
                      );
                },
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                'High Contrast',
                'Increase contrast for better visibility',
                preferences.highContrast,
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(highContrast: value),
                      );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reading Card
          _buildCard(
            'Reading',
            Icons.menu_book,
            const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            [
              _buildDropdownTile(
                context,
                ref,
                'Font Size',
                'Adjust text size for comfortable reading',
                preferences.fontSize,
                [
                  ('small', 'Small'),
                  ('medium', 'Medium'),
                  ('large', 'Large'),
                ],
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(fontSize: value),
                      );
                },
              ),
              const Divider(height: 32),
              _buildDropdownTile(
                context,
                ref,
                'Reading Mode',
                'Choose your preferred layout',
                preferences.readingMode,
                [
                  ('comfortable', 'Comfortable'),
                  ('compact', 'Compact'),
                ],
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(readingMode: value),
                      );
                },
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                'Auto-Bookmark',
                'Automatically save your reading position',
                preferences.autoBookmark,
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(autoBookmark: value),
                      );
                },
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                'Reading Reminders',
                'Get reminded to continue reading',
                preferences.readingReminders,
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(readingReminders: value),
                      );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Localization Card
          _buildCard(
            'Localization',
            Icons.language,
            const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
            [
              _buildDropdownTile(
                context,
                ref,
                'Language',
                'Choose your preferred language',
                preferences.language,
                [
                  ('en', 'English'),
                  ('es', 'Español'),
                  ('fr', 'Français'),
                  ('de', 'Deutsch'),
                  ('pt', 'Português'),
                ],
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(language: value),
                      );
                },
              ),
              const Divider(height: 32),
              _buildDropdownTile(
                context,
                ref,
                'Time Zone',
                'Set your local time zone',
                preferences.timeZone,
                [
                  ('utc', 'UTC'),
                  ('est', 'Eastern (EST)'),
                  ('cst', 'Central (CST)'),
                  ('mst', 'Mountain (MST)'),
                  ('pst', 'Pacific (PST)'),
                  ('gmt', 'GMT'),
                ],
                (value) {
                  ref.read(preferencesProvider.notifier).updatePreference(
                        preferences.copyWith(timeZone: value),
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    String title,
    IconData icon,
    Gradient gradient,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    String currentValue,
    List<(String, String)> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: currentValue,
            isExpanded: true,
            underline: const SizedBox(),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option.$1,
                child: Text(option.$2),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

