import 'package:flutter/material.dart';
import '../../../../core/utils/storage_utils.dart';

/// Widget displaying storage warning when space is low
class StorageWarningWidget extends StatelessWidget {
  final int availableBytes;
  final VoidCallback? onManageStorage;

  const StorageWarningWidget({
    super.key,
    required this.availableBytes,
    this.onManageStorage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = availableBytes < StorageUtils.lowStorageThreshold;
    final isCritical = availableBytes < StorageUtils.minRequiredStorage;

    if (!isLow) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? theme.colorScheme.error
              : theme.colorScheme.tertiary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
            color: isCritical
                ? theme.colorScheme.error
                : theme.colorScheme.tertiary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'Storage Critical' : 'Low Storage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCritical
                        ? theme.colorScheme.error
                        : theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCritical
                      ? 'Not enough space to download. Free up at least ${StorageUtils.formatBytes(StorageUtils.minRequiredStorage)}.'
                      : 'Only ${StorageUtils.formatBytes(availableBytes)} available. Consider freeing up space.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCritical
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          if (onManageStorage != null)
            TextButton(
              onPressed: onManageStorage,
              child: const Text('Manage'),
            ),
        ],
      ),
    );
  }
}
