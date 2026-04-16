import 'package:flutter/material.dart';
import '../../../../core/download/download_manager.dart';
import '../../../../core/utils/storage_utils.dart';

/// Widget showing download progress bar and percentage
class DownloadProgressWidget extends StatelessWidget {
  final DownloadProgress progress;
  final bool showDetails;

  const DownloadProgressWidget({
    super.key,
    required this.progress,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress.progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(context, progress.status),
            ),
          ),
        ),
        
        if (showDetails) ...[
          const SizedBox(height: 8),
          
          // Progress details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status and percentage
              Text(
                _getStatusText(progress.status, percentage),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              // Downloaded size
              if (progress.totalBytes > 0)
                Text(
                  '${StorageUtils.formatBytes(progress.bytesDownloaded)} / ${StorageUtils.formatBytes(progress.totalBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
        
        // Error message
        if (progress.error != null) ...[
          const SizedBox(height: 4),
          Text(
            progress.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Color _getProgressColor(BuildContext context, DownloadStatus status) {
    final theme = Theme.of(context);
    
    switch (status) {
      case DownloadStatus.completed:
        return theme.colorScheme.primary;
      case DownloadStatus.downloading:
        return theme.colorScheme.primary;
      case DownloadStatus.paused:
        return theme.colorScheme.tertiary;
      case DownloadStatus.failed:
        return theme.colorScheme.error;
      case DownloadStatus.cancelled:
        return theme.colorScheme.onSurfaceVariant;
      case DownloadStatus.queued:
        return theme.colorScheme.secondary;
    }
  }

  String _getStatusText(DownloadStatus status, String percentage) {
    switch (status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading $percentage%';
      case DownloadStatus.paused:
        return 'Paused $percentage%';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }
}
