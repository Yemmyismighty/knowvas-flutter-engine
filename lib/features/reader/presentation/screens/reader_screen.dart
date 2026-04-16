import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';


import '../../../../core/download/download_manager_provider.dart';
import '../../../../shared/models/library_item.dart';
import '../../../auth/data/repositories/auth_repository_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/highlights_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/reader_state.dart';
import '../widgets/bookmarks_drawer.dart';
import '../widgets/create_highlight_dialog.dart';
import '../widgets/enhanced_reader_controls.dart';
import '../widgets/enhanced_reader_settings.dart';
import '../widgets/highlights_drawer.dart';
import '../widgets/widgets.dart';

/// Reader screen that embeds native reader views for EPUB, PDF, and Comic content
/// Handles loading states, errors, and back navigation with confirmation
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    required this.contentId,
    this.contentType,
    super.key,
  });

  final int contentId;
  final String? contentType;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _isInitializing = true;
  String? _initError;
  LibraryItem? _libraryItem;

  @override
  void initState() {
    super.initState();
    _initializeReader();
  }

  /// Initialize the reader by loading content and opening native reader
  Future<void> _initializeReader() async {
    try {
      setState(() {
        _isInitializing = true;
        _initError = null;
      });

      // Get library items to find the content
      final libraryState = ref.read(libraryProvider);
      final libraryItems = [...libraryState.currentlyReading, ...libraryState.purchased, ...libraryState.recentlyViewed, ...libraryState.finished, ...libraryState.favorites];

      // Find the library item for this content
      _libraryItem = libraryItems.firstWhere(
        (item) => item.id == widget.contentId,
        orElse: () => throw Exception('Content not found in library'),
      );

      // Determine content type if not provided
      final contentType = widget.contentType ?? _libraryItem!.type;

      // Get file URL (either local or remote)
      final fileUrl = await _getFileUrl();

      // Get auth token from repository
      final authRepository = ref.read(authRepositoryProvider);
      final token = await authRepository.getAccessToken() ?? '';

      // Open reader through provider
      await ref.read(readerProvider.notifier).openContent(
            contentId: widget.contentId,
            contentType: contentType,
            fileUrl: fileUrl,
            token: token,
          );

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  /// Get file URL for the content (local if downloaded, remote otherwise)
  Future<String> _getFileUrl() async {
    if (_libraryItem == null) {
      throw Exception('Library item not loaded');
    }

    final contentType = widget.contentType ?? _libraryItem!.type;

    // For EPUB content, use sample EPUB from assets
    if (contentType == 'epub') {
      // Copy sample EPUB from assets to local storage
      final ByteData data = await rootBundle.load('assets/sample.epub');
      final List<int> bytes = data.buffer.asUint8List();
      
      // Get app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localPath = '${appDocDir.path}/sample.epub';
      final File localFile = File(localPath);
      
      // Write the EPUB file
      await localFile.writeAsBytes(bytes);
      
      return localPath;
    }

    // Check if content is downloaded
    if (false) {
      // Get decrypted file path from download manager
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final downloadManager = ref.read(downloadManagerProvider);
      final decryptedPath = await downloadManager.getDecryptedFilePath(
        widget.contentId,
        userId,
      );
      
      return decryptedPath;
    } else {
      // Use remote URL (would need to get signed URL from backend)
      // For now, return the content URL from the library item
      // In production, this should call the backend to get a signed download URL
      return _libraryItem!.cover ?? ''; // Placeholder - should be actual content URL
    }
  }

  /// Handle back navigation with confirmation if there are unsaved changes
  Future<bool> _handleBackNavigation() async {
    final readerState = ref.read(readerProvider);
    
    // If reader is open and has progress, show confirmation
    if (readerState.isReaderOpen && readerState.currentPage != null) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Close Reader?'),
          content: const Text(
            'Your reading progress has been saved. Do you want to close the reader?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (shouldPop == true) {
        await ref.read(readerProvider.notifier).closeContent();
        return true;
      }
      return false;
    }

    // No confirmation needed, just close
    await ref.read(readerProvider.notifier).closeContent();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _handleBackNavigation();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildBody(readerState),
        ),
      ),
    );
  }

  /// Build the main body based on current state
  Widget _buildBody(ReaderState readerState) {
    // Show initialization loading
    if (_isInitializing) {
      return _buildLoadingState('Initializing reader...');
    }

    // Show initialization error
    if (_initError != null) {
      return _buildErrorState(_initError!);
    }

    // Show reader loading state
    if (readerState.isLoading) {
      return _buildLoadingState('Loading content...');
    }

    // Show reader error
    if (readerState.error != null) {
      return _buildErrorState(readerState.error!);
    }

    // Show native reader view
    if (readerState.isReaderOpen) {
      return _buildNativeReaderView();
    }

    // Default state
    return _buildErrorState('Reader not initialized');
  }

  /// Build loading state UI
  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          if (_libraryItem != null) ...[
            const SizedBox(height: 16),
            Text(
              _libraryItem!.title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Build error state UI
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to Open Reader',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _initializeReader,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build native reader view using platform view
  Widget _buildNativeReaderView() {
    final contentTitle = _libraryItem?.title ?? 'Reader';

    return Stack(
      children: [
        // Native reader view
        _buildPlatformView(),
        // Enhanced reader controls overlay
        EnhancedReaderControls(
          contentTitle: contentTitle,
          contentAuthor: _libraryItem?.author ?? '',
          onBackTap: () async {
            final shouldPop = await _handleBackNavigation();
            if (shouldPop && mounted) {
              context.pop();
            }
          },
          onBookmarkTap: _handleBookmarkTap,
          onBookmarksListTap: _handleBookmarksListTap,
          onHighlightsListTap: _handleHighlightsListTap,
          onSettingsTap: _handleSettingsTap,
          onTableOfContentsTap: _handleTableOfContentsTap,
        ),
      ],
    );
  }

  /// Build platform-specific view
  Widget _buildPlatformView() {
    final readerState = ref.read(readerProvider);
    
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'com.knowvas.reader/view',
        creationParams: {
          'session_id': readerState.sessionId,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'com.knowvas.reader/view',
        creationParams: {
          'session_id': readerState.sessionId,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return _buildErrorState('Platform not supported');
    }
  }

  /// Handle add bookmark button tap
  Future<void> _handleBookmarkTap() async {
    final readerState = ref.read(readerProvider);
    if (readerState.currentPage == null) {
      return;
    }

    try {
      await ref
          .read(bookmarksProvider(widget.contentId).notifier)
          .addBookmark(pageNumber: readerState.currentPage!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bookmark added at page ${readerState.currentPage! + 1}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bookmark: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle bookmarks list button tap
  void _handleBookmarksListTap() {
    showDialog(
      context: context,
      builder: (context) => BookmarksDrawer(
        contentId: widget.contentId,
        onBookmarkTap: _navigateToPage,
      ),
    );
  }

  /// Handle highlights list button tap
  void _handleHighlightsListTap() {
    showDialog(
      context: context,
      builder: (context) => HighlightsDrawer(
        contentId: widget.contentId,
        onHighlightTap: _navigateToPage,
      ),
    );
  }

  /// Navigate to a specific page
  void _navigateToPage(int pageNumber) {
    // TODO: Implement page navigation through platform channel
    // This would require adding a method to ReaderChannel to jump to a specific page
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to page ${pageNumber + 1}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle text selection for highlight creation
  /// This would be called from native platform when text is selected
  Future<void> _handleTextSelection({
    required String selectedText,
    required int pageNumber,
    required int startPosition,
    required int endPosition,
  }) async {
    final color = await showCreateHighlightDialog(
      context,
      selectedText: selectedText,
      pageNumber: pageNumber,
    );

    if (color != null) {
      try {
        await ref
            .read(highlightsProvider(widget.contentId).notifier)
            .addHighlight(
              pageNumber: pageNumber,
              startPosition: startPosition,
              endPosition: endPosition,
              highlightedText: selectedText,
              color: color,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Highlight created'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create highlight: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Handle settings button tap
  void _handleSettingsTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedReaderSettings(),
    );
  }

  /// Handle table of contents button tap
  void _handleTableOfContentsTap() {
    // TODO: Implement table of contents
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Table of Contents - Coming Soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Handle platform view creation
  void _onPlatformViewCreated(int id) {
    // Platform view created successfully
    // Native reader should now be visible
  }

  @override
  void dispose() {
    // Close reader when screen is disposed
    ref.read(readerProvider.notifier).closeContent();
    super.dispose();
  }
}

