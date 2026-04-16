import 'package:flutter/material.dart';

/// Reusable empty state widget
/// Provides consistent empty state UI across the app
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: action,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty library state
class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({
    super.key,
    this.onExplore,
  });

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.library_books_outlined,
      title: 'Your library is empty',
      message: 'Start exploring and add content to your library',
      action: onExplore,
      actionLabel: 'Explore Content',
    );
  }
}

/// Empty search results state
class EmptySearchState extends StatelessWidget {
  const EmptySearchState({
    super.key,
    this.query,
  });

  final String? query;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      message: query != null
          ? 'No results for "$query". Try different keywords.'
          : 'Try searching for books, authors, or genres.',
    );
  }
}

/// Empty cart state
class EmptyCartState extends StatelessWidget {
  const EmptyCartState({
    super.key,
    this.onBrowse,
  });

  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      message: 'Add items to your cart to get started',
      action: onBrowse,
      actionLabel: 'Browse Content',
    );
  }
}

/// Empty bookmarks state
class EmptyBookmarksState extends StatelessWidget {
  const EmptyBookmarksState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.bookmark_border,
      title: 'No bookmarks yet',
      message: 'Bookmark pages while reading to find them easily later',
    );
  }
}

/// Empty highlights state
class EmptyHighlightsState extends StatelessWidget {
  const EmptyHighlightsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.highlight_outlined,
      title: 'No highlights yet',
      message: 'Highlight text while reading to save important passages',
    );
  }
}

/// Empty collections state
class EmptyCollectionsState extends StatelessWidget {
  const EmptyCollectionsState({
    super.key,
    this.onCreate,
  });

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.folder_outlined,
      title: 'No collections yet',
      message: 'Create collections to organize your library',
      action: onCreate,
      actionLabel: 'Create Collection',
    );
  }
}

/// Empty downloads state
class EmptyDownloadsState extends StatelessWidget {
  const EmptyDownloadsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.download_outlined,
      title: 'No downloads',
      message: 'Download content to read offline',
    );
  }
}
