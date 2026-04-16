import 'package:flutter/material.dart';
import '../../../../core/download/download_manager.dart';
import '../../../../core/utils/storage_utils.dart';
import '../../../../shared/models/library_item.dart';
import 'download_progress_widget.dart';
import 'download_controls_widget.dart';

/// Card widget for displaying a download item with progress and controls
class DownloadItemCard extends StatelessWidget {
  final LibraryItem? item;
  final DownloadProgress? progress;
  final DownloadedContent? completed;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;

  const DownloadItemCard({
    super.key,
    this.item,
    this.progress,
    this.completed,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onDelete,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = completed != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: isCompleted ? onOpen : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image
                  if (item != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item!.cover ?? '',
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 90,
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.book,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(width: 12),
                  
                  // Content info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          item?.title ?? 'Unknown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Author
                        if (item != null)
                          Text(
                            item!.author,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        const SizedBox(height: 4),
                        
                        // File size for completed downloads
                        if (isCompleted)
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Downloaded • ${StorageUtils.formatBytes(completed!.fileSize)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  // Controls
                  if (progress != null)
                    DownloadControlsWidget(
                      progress: progress!,
                      onPause: onPause,
                      onResume: onResume,
                      onCancel: onCancel,
                    )
                  else if (isCompleted)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete?.call();
                        } else if (value == 'open') {
                          onOpen?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new),
                              SizedBox(width: 8),
                              Text('Open'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Progress bar for active downloads
              if (progress != null) ...[
                const SizedBox(height: 12),
                DownloadProgressWidget(
                  progress: progress!,
                  showDetails: true,
                ),
              ],
              
              // Download date for completed
              if (isCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  'Downloaded ${_formatDate(completed!.downloadDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
