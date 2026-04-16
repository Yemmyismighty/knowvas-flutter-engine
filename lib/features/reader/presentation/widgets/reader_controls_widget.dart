import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reader_provider.dart';
import '../providers/reader_state.dart';

/// Reader controls overlay with top and bottom bars
/// Provides navigation, bookmarking, settings, and progress tracking
class ReaderControlsWidget extends ConsumerStatefulWidget {
  const ReaderControlsWidget({
    required this.contentTitle,
    this.onBookmarkTap,
    this.onBookmarksListTap,
    this.onHighlightsListTap,
    this.onSettingsTap,
    this.onBackTap,
    super.key,
  });

  final String contentTitle;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onBookmarksListTap;
  final VoidCallback? onHighlightsListTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onBackTap;

  @override
  ConsumerState<ReaderControlsWidget> createState() =>
      _ReaderControlsWidgetState();
}

class _ReaderControlsWidgetState extends ConsumerState<ReaderControlsWidget>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  late AnimationController _animationController;
  late Animation<Offset> _topBarAnimation;
  late Animation<Offset> _bottomBarAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  /// Initialize slide animations for top and bottom bars
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _topBarAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _bottomBarAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Show controls initially
    _animationController.forward();
  }

  /// Toggle controls visibility
  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);

    return GestureDetector(
      onTap: _toggleVisibility,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Top bar
          _buildTopBar(context),
          // Bottom bar
          _buildBottomBar(context, readerState),
        ],
      ),
    );
  }

  /// Build top bar with title, bookmark, and settings buttons
  Widget _buildTopBar(BuildContext context) {
    return SlideTransition(
      position: _topBarAnimation,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: widget.onBackTap,
                    tooltip: 'Back',
                  ),
                  // Title
                  Expanded(
                    child: Text(
                      widget.contentTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Bookmarks list button
                  IconButton(
                    icon: const Icon(Icons.bookmarks),
                    color: Colors.white,
                    onPressed: widget.onBookmarksListTap,
                    tooltip: 'Bookmarks',
                  ),
                  // Highlights list button
                  IconButton(
                    icon: const Icon(Icons.format_color_text),
                    color: Colors.white,
                    onPressed: widget.onHighlightsListTap,
                    tooltip: 'Highlights',
                  ),
                  // Add bookmark button
                  IconButton(
                    icon: const Icon(Icons.bookmark_add),
                    color: Colors.white,
                    onPressed: widget.onBookmarkTap,
                    tooltip: 'Add Bookmark',
                  ),
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings),
                    color: Colors.white,
                    onPressed: widget.onSettingsTap,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build bottom bar with progress slider and page number
  Widget _buildBottomBar(BuildContext context, ReaderState readerState) {
    final currentPage = readerState.currentPage ?? 0;
    final totalPages = readerState.totalPages ?? 0;
    final progress = readerState.progress;

    return SlideTransition(
      position: _bottomBarAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress slider
                  if (totalPages > 0) ...[
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                        trackHeight: 3.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          // Calculate target page from progress
                          final targetPage = (value * totalPages).round();
                          _onPageChanged(targetPage);
                        },
                        min: 0.0,
                        max: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Page number display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current page / Total pages
                      Text(
                        totalPages > 0
                            ? 'Page ${currentPage + 1} of $totalPages'
                            : 'Loading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Progress percentage
                      if (totalPages > 0)
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle page change from slider
  void _onPageChanged(int targetPage) {
    // TODO: Implement page navigation through platform channel
    // This would require adding a method to ReaderChannel to jump to a specific page
    // For now, we just update the local state
    // The actual implementation would call something like:
    // ref.read(readerProvider.notifier).jumpToPage(targetPage);
  }
}
