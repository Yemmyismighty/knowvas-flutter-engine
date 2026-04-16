import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/content.dart';
import '../providers/collection_provider.dart';
import '../providers/collection_state.dart';
import '../widgets/library_item_card.dart';

/// Collection detail screen
/// Shows collection details and items
class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({
    required this.collectionId,
    super.key,
  });

  final int collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionDetailState = ref.watch(
      collectionDetailProvider(collectionId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'),
        actions: [
          if (collectionDetailState.collection != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddContentDialog(context, ref),
              tooltip: 'Add content',
            ),
        ],
      ),
      body: _buildBody(context, ref, collectionDetailState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CollectionDetailState state,
  ) {
    if (state.isLoading && state.collection == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(collectionDetailProvider(collectionId).notifier)
                    .refresh(collectionId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final collection = state.collection;
    if (collection == null) {
      return const Center(
        child: Text('Collection not found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionDetailProvider(collectionId).notifier)
          .refresh(collectionId),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (collection.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      collection.description!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        collection.isPublic ? Icons.public : Icons.lock,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        collection.isPublic ? 'Public' : 'Private',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.collections_bookmark,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${collection.itemCount} items',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
          ),
          if (collection.items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.collections_bookmark_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items in this collection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add content to organize your library',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final content = collection.items[index];
                    return _ContentCard(
                      content: content,
                      onTap: () {
                        // Navigate to content detail or reader
                        context.push('/content/${content.id}');
                      },
                      onRemove: () => _showRemoveConfirmation(
                        context,
                        ref,
                        content,
                      ),
                    );
                  },
                  childCount: collection.items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddContentDialog(BuildContext context, WidgetRef ref) {
    // In a real implementation, this would show a dialog to select content
    // from the user's library to add to the collection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add content feature - to be implemented with library integration'),
      ),
    );
  }

  void _showRemoveConfirmation(
    BuildContext context,
    WidgetRef ref,
    Content content,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Collection'),
        content: Text(
          'Are you sure you want to remove "${content.title}" from this collection?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(collectionDetailProvider(collectionId).notifier)
                  .removeContent(collectionId, content.id);

              if (success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Content removed from collection'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.content,
    required this.onTap,
    required this.onRemove,
  });

  final Content content;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    content.cover ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, size: 48),
                      );
                    },
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle),
                      color: Colors.red,
                      onPressed: onRemove,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content.authorName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
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
    );
  }
}
