import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/highlight.dart';
import '../providers/highlights_provider.dart';

/// Drawer showing all highlights for the current content
/// Displays highlighted text with color indicators and allows deletion
class HighlightsDrawer extends ConsumerWidget {
  const HighlightsDrawer({
    required this.contentId,
    this.onHighlightTap,
    super.key,
  });

  final int contentId;
  final void Function(int pageNumber)? onHighlightTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightsAsync = ref.watch(highlightsProvider(contentId));

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            const Divider(height: 1),
            // Highlights list
            Expanded(
              child: highlightsAsync.when(
                data: (highlights) => _buildHighlightsList(
                  context,
                  ref,
                  highlights,
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
            Icons.highlight,
            size: 28,
            color: Colors.amber,
          ),
          const SizedBox(width: 12),
          const Text(
            'Highlights',
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

  /// Build highlights list
  Widget _buildHighlightsList(
    BuildContext context,
    WidgetRef ref,
    List<Highlight> highlights,
  ) {
    if (highlights.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: highlights.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final highlight = highlights[index];
        return _buildHighlightItem(context, ref, highlight);
      },
    );
  }

  /// Build individual highlight item
  Widget _buildHighlightItem(
    BuildContext context,
    WidgetRef ref,
    Highlight highlight,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(highlight.createdAt);
    final highlightColor = _parseColor(highlight.color);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        width: 4,
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: highlightColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          highlight.highlightedText,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Text(
              'Page ${highlight.pageNumber + 1}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: Colors.red,
        onPressed: () => _showDeleteConfirmation(
          context,
          ref,
          highlight,
        ),
        tooltip: 'Delete highlight',
      ),
      onTap: () {
        Navigator.of(context).pop();
        onHighlightTap?.call(highlight.pageNumber);
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
              Icons.highlight_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Highlights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select text to create highlights',
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
              'Failed to Load Highlights',
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
    Highlight highlight,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Highlight?'),
        content: const Text(
          'Are you sure you want to delete this highlight?',
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

    if (confirmed == true && highlight.id != null) {
      try {
        await ref
            .read(highlightsProvider(contentId).notifier)
            .deleteHighlight(highlight.id!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Highlight deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete highlight: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Parse color string to Color object
  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      final hexColor = colorString.replaceAll('#', '');
      // Add FF for full opacity if not present
      final fullHex = hexColor.length == 6 ? 'FF$hexColor' : hexColor;
      return Color(int.parse(fullHex, radix: 16));
    } catch (e) {
      // Default to yellow if parsing fails
      return Colors.yellow;
    }
  }
}
