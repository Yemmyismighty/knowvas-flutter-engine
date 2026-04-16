import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

/// Theme selector widget for settings screen
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(settingsProvider.select((prefs) => prefs.theme));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ThemeOption(
                title: 'Light',
                icon: Icons.light_mode,
                isSelected: currentTheme == 'light',
                onTap: () => ref.read(settingsProvider.notifier).updateTheme('light'),
                previewColor: Colors.white,
                previewTextColor: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                title: 'Dark',
                icon: Icons.dark_mode,
                isSelected: currentTheme == 'dark',
                onTap: () => ref.read(settingsProvider.notifier).updateTheme('dark'),
                previewColor: const Color(0xFF1A1A1A),
                previewTextColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                title: 'Sepia',
                icon: Icons.auto_stories,
                isSelected: currentTheme == 'sepia',
                onTap: () => ref.read(settingsProvider.notifier).updateTheme('sepia'),
                previewColor: AppTheme.sepiaBackground,
                previewTextColor: AppTheme.sepiaText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'System theme will follow your device settings',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color previewColor;
  final Color previewTextColor;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.previewColor,
    required this.previewTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandPrimary.withOpacity(0.1)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected
                ? AppTheme.brandPrimary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            // Preview circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: previewTextColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.brandPrimary : null,
                  ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                color: AppTheme.brandPrimary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
