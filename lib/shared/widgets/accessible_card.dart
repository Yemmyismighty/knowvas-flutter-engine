import 'package:flutter/material.dart';
import '../../core/utils/accessibility_utils.dart';

/// Accessible card widget with semantic labels for content items
class AccessibleContentCard extends StatelessWidget {
  const AccessibleContentCard({
    super.key,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.rating,
    this.progress,
    this.contentType,
    this.onTap,
    this.onLongPress,
    this.isDownloaded = false,
    this.isFavorite = false,
  });

  final String title;
  final String author;
  final String coverUrl;
  final double? rating;
  final double? progress;
  final String? contentType;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDownloaded;
  final bool isFavorite;

  String _buildSemanticLabel() {
    final buffer = StringBuffer();
    
    // Content type
    if (contentType != null) {
      buffer.write('${AccessibilityUtils.contentTypeLabel(contentType!)}, ');
    }
    
    // Title and author
    buffer.write('$title by $author. ');
    
    // Rating
    if (rating != null) {
      buffer.write('${AccessibilityUtils.ratingLabel(rating!)}. ');
    }
    
    // Progress
    if (progress != null) {
      buffer.write('${AccessibilityUtils.readingProgressLabel(progress!)}. ');
    }
    
    // Downloaded status
    if (isDownloaded) {
      buffer.write('Downloaded. ');
    }
    
    // Favorite status
    if (isFavorite) {
      buffer.write('Marked as favorite. ');
    }
    
    // Action hint
    buffer.write('Double tap to open');
    if (onLongPress != null) {
      buffer.write(', long press for options');
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      enabled: onTap != null,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Stack(
                    children: [
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 48),
                          );
                        },
                      ),
                      // Badges
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            if (isDownloaded)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.download_done,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            if (isFavorite)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Progress bar
                      if (progress != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                    ],
                  ),
                ),
                // Content info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        author,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible list item for library content
class AccessibleLibraryListItem extends StatelessWidget {
  const AccessibleLibraryListItem({
    super.key,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.progress,
    this.lastOpened,
    this.onTap,
    this.onLongPress,
    this.isDownloaded = false,
  });

  final String title;
  final String author;
  final String coverUrl;
  final double? progress;
  final DateTime? lastOpened;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDownloaded;

  String _buildSemanticLabel() {
    final buffer = StringBuffer();
    buffer.write('$title by $author. ');
    
    if (progress != null) {
      buffer.write('${AccessibilityUtils.readingProgressLabel(progress!)}. ');
    }
    
    if (lastOpened != null) {
      final now = DateTime.now();
      final difference = now.difference(lastOpened!);
      if (difference.inDays == 0) {
        buffer.write('Last opened today. ');
      } else if (difference.inDays == 1) {
        buffer.write('Last opened yesterday. ');
      } else {
        buffer.write('Last opened ${difference.inDays} days ago. ');
      }
    }
    
    if (isDownloaded) {
      buffer.write('Downloaded. ');
    }
    
    buffer.write('Double tap to open');
    if (onLongPress != null) {
      buffer.write(', long press for options');
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      enabled: onTap != null,
      child: ExcludeSemantics(
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              coverUrl,
              width: 48,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 64,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book),
                );
              },
            ),
          ),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(author),
              if (progress != null) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                ),
              ],
            ],
          ),
          trailing: isDownloaded
              ? const Icon(Icons.download_done, color: Colors.green)
              : null,
        ),
      ),
    );
  }
}

