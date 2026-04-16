import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/bookmark.dart';
import '../providers/bookmarks_provider.dart';

/// Drawer showing all bookmarks for the current content
/// Allows navigation to bookmarked pages and deletion
class BookmarksDrawer extends ConsumerWidget {
  const BookmarksDrawer({
    required this.contentId,
    this.onBookmarkTap,
    super.key,
  });

  final int contentId;
  final void Function(int pageNumber)? onBookmarkTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider(contentId));

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            const Divider(height: 1),
            // Bookmarks list
            Expanded(
              child: bookmarksAsync.when(
                data: (bookmarks) => _buildBookmarksList(
                  context,
                  ref,
                  bookmarks,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => _buildErrorState(context, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build drawer header
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(
            Icons.bookmark,
            size: 28,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          const Text(
            'Bookmarks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  /// Build bookmarks list
  Widget _buildBookmarksList(
    BuildContext context,
    WidgetRef ref,
    List<Bookmark> bookmarks,
  ) {
    if (bookmarks.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookmarks.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _buildBookmarkItem(context, ref, bookmark);
      },
    );
  }

  /// Build individual bookmark item
  Widget _buildBookmarkItem(
    BuildContext context,
    WidgetRef ref,
    Bookmark bookmark,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(bookmark.createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Text(
          '${bookmark.pageNumber + 1}',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        'Page ${bookmark.pageNumber + 1}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        formattedDate,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: Colors.red,
        onPressed: () => _showDeleteConfirmation(
          context,
          ref,
          bookmark,
        ),
        tooltip: 'Delete bookmark',
      ),
      onTap: () {
        Navigator.of(context).pop();
        onBookmarkTap?.call(bookmark.pageNumber);
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Bookmarks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon to save your current page',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Bookmarks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Bookmark bookmark,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark?'),
        content: Text(
          'Are you sure you want to delete the bookmark at page ${bookmark.pageNumber + 1}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && bookmark.id != null) {
      try {
        await ref
            .read(bookmarksProvider(contentId).notifier)
            .deleteBookmark(bookmark.id!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete bookmark: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
