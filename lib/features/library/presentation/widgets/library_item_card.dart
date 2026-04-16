import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/library_item.dart';
import '../providers/library_provider.dart';

/// Card widget for displaying library items
/// Supports both grid and list view layouts
/// Shows cover, title, author, progress bar, and download indicator
class LibraryItemCard extends ConsumerWidget {
  const LibraryItemCard({
    super.key,
    required this.item,
    required this.isGridView,
  });

  final LibraryItem item;
  final bool isGridView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isGridView ? _buildGridCard(context, ref) : _buildListCard(context, ref);
  }

  Widget _buildGridCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openReader(context),
        onLongPress: () => _showContextMenu(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with badges
            Expanded(
              child: Stack(
                children: [
                  // Cover image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                    ),
                    child: (item.cover != null && item.cover!.isNotEmpty)
                        ? Image.network(
                            item.cover ?? "",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder();
                            },
                          )
                        : _buildPlaceholder(),
                  ),

                  // Download indicator badge
                  if (false)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.download_done,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),

                  // Favorite indicator
                  if (item.isFavorite)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Author
                  Text(
                    item.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  if (item.progress > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(item.progress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => _openReader(context),
        onLongPress: () => _showContextMenu(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (item.cover != null && item.cover!.isNotEmpty)
                        ? Image.network(
                            item.cover ?? "",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder();
                            },
                          )
                        : _buildPlaceholder(),
                  ),

                  // Download indicator badge
                  if (false)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.download_done,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Content info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with favorite indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isFavorite)
                          Icon(
                            Icons.favorite,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      item.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Content type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getTypeColor(item.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeLabel(item.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getTypeColor(item.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    if (item.progress > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: item.progress,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(item.progress * 100).toInt()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (item.currentPage != null &&
                              item.totalPages != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Page ${item.currentPage} of ${item.totalPages}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      Text(
                        'Not started',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.book,
        size: 48,
        color: Colors.grey.shade400,
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'ebook':
        return 'Book';
      case 'comic':
        return 'Comic';
      case 'magazine':
        return 'Magazine';
      case 'audiobook':
        return 'Audiobook';
      case 'pdf':
        return 'PDF';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'ebook':
        return Colors.blue;
      case 'comic':
        return Colors.purple;
      case 'magazine':
        return Colors.orange;
      case 'audiobook':
        return Colors.green;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _openReader(BuildContext context) {
    // TODO: Navigate to reader screen
    // This will be implemented in a later task
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${item.title}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Show context menu with library item actions
  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _LibraryItemActionsSheet(
        item: item,
        onDownload: () => _handleDownload(context, ref),
        onRemove: () => _handleRemove(context, ref),
        onAddToCollection: () => _handleAddToCollection(context, ref),
        onToggleFavorite: () => _handleToggleFavorite(context, ref),
      ),
    );
  }

  /// Handle download action
  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Close bottom sheet

    if (false) {
      // Already downloaded, show message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content is already downloaded'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // TODO: Implement download with download manager (Task 25)
    // For now, just show a placeholder message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading ${item.title}...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Simulate download completion after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    // Update item as downloaded
    await ref.read(libraryProvider.notifier).updateItem(
      contentId: item.id,
      isDownloaded: true,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} downloaded successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle remove from library action
  Future<void> _handleRemove(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Close bottom sheet

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Library'),
        content: Text(
          'Are you sure you want to remove "${item.title}" from your library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(libraryProvider.notifier).removeFromLibrary(
          item.id,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} removed from library'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove from library: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Handle add to collection action
  Future<void> _handleAddToCollection(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Close bottom sheet

    // TODO: Implement collections feature (Task 24)
    // For now, just show a placeholder message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collections feature coming soon'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle toggle favorite action
  Future<void> _handleToggleFavorite(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Close bottom sheet

    final newFavoriteStatus = !item.isFavorite;

    try {
      await ref.read(libraryProvider.notifier).updateItem(
        contentId: item.id,
        isFavorite: newFavoriteStatus,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus
                  ? '${item.title} added to favorites'
                  : '${item.title} removed from favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Bottom sheet widget for library item actions
class _LibraryItemActionsSheet extends StatelessWidget {
  const _LibraryItemActionsSheet({
    required this.item,
    required this.onDownload,
    required this.onRemove,
    required this.onAddToCollection,
    required this.onToggleFavorite,
  });

  final LibraryItem item;
  final VoidCallback onDownload;
  final VoidCallback onRemove;
  final VoidCallback onAddToCollection;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cover thumbnail
                Container(
                  width: 50,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (item.cover != null && item.cover!.isNotEmpty)
                      ? Image.network(
                          item.cover ?? "",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.book,
                              size: 24,
                              color: Colors.grey.shade400,
                            );
                          },
                        )
                      : Icon(
                          Icons.book,
                          size: 24,
                          color: Colors.grey.shade400,
                        ),
                ),
                const SizedBox(width: 12),
                // Title and author
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.author,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Actions
          ListTile(
            leading: Icon(
              false ? Icons.download_done : Icons.download,
              color: false ? Colors.green : null,
            ),
            title: Text(
              false ? 'Downloaded' : 'Download',
            ),
            onTap: onDownload,
            enabled: !false,
          ),
          ListTile(
            leading: Icon(
              item.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: item.isFavorite ? Colors.red : null,
            ),
            title: Text(
              item.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            ),
            onTap: onToggleFavorite,
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark),
            title: const Text('Add to Collection'),
            onTap: onAddToCollection,
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            title: const Text(
              'Remove from Library',
              style: TextStyle(color: Colors.red),
            ),
            onTap: onRemove,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

