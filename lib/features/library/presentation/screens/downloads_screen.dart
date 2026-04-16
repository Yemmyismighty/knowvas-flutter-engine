import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/storage_utils.dart';
import '../../../../shared/models/library_item.dart';
import '../providers/downloads_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/download_item_card.dart';
import '../widgets/storage_warning_widget.dart';

/// Downloads screen showing all downloads with status
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _availableStorage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkStorage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkStorage() async {
    final storage = await StorageUtils.getAvailableStorage();
    if (mounted) {
      setState(() {
        _availableStorage = storage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadsState = ref.watch(downloadsProvider);
    final libraryState = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Active (${downloadsState.activeDownloads.length})',
            ),
            Tab(
              text: 'Completed (${downloadsState.completedDownloads.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(downloadsProvider.notifier).refresh();
              _checkStorage();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Storage warning
          StorageWarningWidget(
            availableBytes: _availableStorage,
            onManageStorage: () {
              _showManageStorageDialog(context);
            },
          ),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active downloads tab
                _buildActiveDownloadsTab(
                  downloadsState,
                  libraryState,
                ),

                // Completed downloads tab
                _buildCompletedDownloadsTab(
                  downloadsState,
                  libraryState,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDownloadsTab(
    DownloadsState downloadsState,
    LibraryState libraryState,
  ) {
    if (downloadsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (downloadsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              downloadsState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(downloadsProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (downloadsState.activeDownloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No active downloads',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Downloads will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: downloadsState.activeDownloads.length,
      itemBuilder: (context, index) {
        final progress =
            downloadsState.activeDownloads.values.elementAt(index);
        final item = _findLibraryItem(
          libraryState,
          progress.contentId,
        );

        return DownloadItemCard(
          item: item,
          progress: progress,
          onPause: () {
            ref
                .read(downloadsProvider.notifier)
                .pauseDownload(progress.contentId);
          },
          onResume: () {
            ref
                .read(downloadsProvider.notifier)
                .resumeDownload(progress.contentId);
          },
          onCancel: () {
            _showCancelConfirmation(context, progress.contentId);
          },
        );
      },
    );
  }

  Widget _buildCompletedDownloadsTab(
    DownloadsState downloadsState,
    LibraryState libraryState,
  ) {
    if (downloadsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (downloadsState.completedDownloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No completed downloads',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Completed downloads will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: downloadsState.completedDownloads.length,
      itemBuilder: (context, index) {
        final completed = downloadsState.completedDownloads[index];
        final item = _findLibraryItem(
          libraryState,
          completed.contentId,
        );

        return DownloadItemCard(
          item: item,
          completed: completed,
          onOpen: () {
            // TODO: Navigate to reader
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening content...'),
              ),
            );
          },
          onDelete: () {
            _showDeleteConfirmation(context, completed.contentId);
          },
        );
      },
    );
  }

  LibraryItem? _findLibraryItem(LibraryState state, int contentId) {
    try {
      final all = [...state.currentlyReading, ...state.purchased, ...state.recentlyViewed, ...state.finished, ...state.favorites];
      return all.firstWhere((item) => item.id == contentId);
    } catch (e) {
      return null;
    }
  }

  void _showCancelConfirmation(BuildContext context, int contentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Download'),
        content: const Text(
          'Are you sure you want to cancel this download? Progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadsProvider.notifier).cancelDownload(contentId);
              Navigator.of(context).pop();
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int contentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text(
          'Are you sure you want to delete this download? You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadsProvider.notifier).deleteDownload(contentId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download deleted'),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Storage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${StorageUtils.formatBytes(_availableStorage)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'To free up space:\n'
              '• Delete unused downloads\n'
              '• Clear app cache\n'
              '• Remove old files from your device',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tabController.animateTo(1); // Switch to completed tab
            },
            child: const Text('View Downloads'),
          ),
        ],
      ),
    );
  }
}
