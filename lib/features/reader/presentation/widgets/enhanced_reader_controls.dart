import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/reader_provider.dart';
import '../providers/reader_state.dart';

/// Enhanced reader controls with beautiful UI matching Knowvas brand
/// Features tap-to-toggle, brand colors, logo, and comprehensive settings
class EnhancedReaderControls extends ConsumerStatefulWidget {
  const EnhancedReaderControls({
    required this.contentTitle,
    required this.contentAuthor,
    this.onBookmarkTap,
    this.onBookmarksListTap,
    this.onHighlightsListTap,
    this.onSettingsTap,
    this.onBackTap,
    this.onTableOfContentsTap,
    super.key,
  });

  final String contentTitle;
  final String contentAuthor;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onBookmarksListTap;
  final VoidCallback? onHighlightsListTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onBackTap;
  final VoidCallback? onTableOfContentsTap;

  @override
  ConsumerState<EnhancedReaderControls> createState() =>
      _EnhancedReaderControlsState();
}

class _EnhancedReaderControlsState extends ConsumerState<EnhancedReaderControls>
    with TickerProviderStateMixin {
  bool _isVisible = true;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<Offset> _topBarAnimation;
  late Animation<Offset> _bottomBarAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scheduleAutoHide();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _topBarAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _bottomBarAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Show controls initially
    _animationController.forward();
    _fadeController.forward();
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _animationController.forward();
        _fadeController.forward();
        _scheduleAutoHide();
      } else {
        _animationController.reverse();
        _fadeController.reverse();
      }
    });
  }

  void _scheduleAutoHide() {
    // Auto-hide after 4 seconds of inactivity
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isVisible) {
        _toggleVisibility();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _toggleVisibility();
        if (_isVisible) {
          _scheduleAutoHide();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Top navigation bar
          _buildTopNavigationBar(context, theme),
          // Bottom controls bar
          _buildBottomControlsBar(context, theme, readerState),
          // Side menu overlay (when visible)
          if (_isVisible) _buildSideMenuOverlay(context, theme),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar(BuildContext context, ThemeData theme) {
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
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.0),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
              child: Row(
                children: [
                  // Back button with brand styling
                  _buildIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onPressed: widget.onBackTap,
                    tooltip: 'Back to Library',
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  
                  // Knowvas logo
                  _buildKnowvasLogo(),
                  const SizedBox(width: AppTheme.spacing16),
                  
                  // Book title and author
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.contentTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.contentAuthor.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'by ${widget.contentAuthor}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppTheme.fontFamily,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  _buildIconButton(
                    icon: Icons.bookmark_add_outlined,
                    onPressed: widget.onBookmarkTap,
                    tooltip: 'Add Bookmark',
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildIconButton(
                    icon: Icons.more_vert,
                    onPressed: () => _showReaderMenu(context),
                    tooltip: 'More Options',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControlsBar(
    BuildContext context,
    ThemeData theme,
    ReaderState readerState,
  ) {
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
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.0),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress slider with enhanced styling
                  if (totalPages > 0) ...[
                    _buildProgressSlider(progress, totalPages, currentPage),
                    const SizedBox(height: AppTheme.spacing16),
                  ],
                  
                  // Bottom action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            totalPages > 0
                                ? 'Page ${currentPage + 1} of $totalPages'
                                : 'Loading...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          if (totalPages > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}% complete',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Quick action buttons
                      Row(
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.list_alt,
                            label: 'Contents',
                            onPressed: widget.onTableOfContentsTap,
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          _buildQuickActionButton(
                            icon: Icons.tune,
                            label: 'Settings',
                            onPressed: widget.onSettingsTap,
                          ),
                        ],
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

  Widget _buildProgressSlider(double progress, int totalPages, int currentPage) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.brandPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.brandPrimary,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: AppTheme.brandPrimary,
              overlayColor: AppTheme.brandPrimary.withOpacity(0.2),
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10.0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 20.0,
              ),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final targetPage = (value * totalPages).round();
                _onPageChanged(targetPage);
              },
              min: 0.0,
              max: 1.0,
            ),
          ),
          
          // Time estimates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTimeRemaining(progress),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Text(
                _getReadingTime(totalPages, currentPage),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKnowvasLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo icon (you can replace with actual SVG)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.auto_stories,
              size: 14,
              color: AppTheme.brandPrimary,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Knowvas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        iconSize: 22,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(AppTheme.spacing8),
        constraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.brandPrimary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: AppTheme.brandPrimary.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMenuOverlay(BuildContext context, ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Positioned(
        top: 100,
        right: AppTheme.spacing16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.brandPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuOption(
                  icon: Icons.bookmarks_outlined,
                  title: 'Bookmarks',
                  onTap: widget.onBookmarksListTap,
                ),
                _buildMenuOption(
                  icon: Icons.format_color_text,
                  title: 'Highlights',
                  onTap: widget.onHighlightsListTap,
                ),
                _buildMenuOption(
                  icon: Icons.list_alt,
                  title: 'Table of Contents',
                  onTap: widget.onTableOfContentsTap,
                ),
                _buildMenuOption(
                  icon: Icons.tune,
                  title: 'Reading Settings',
                  onTap: widget.onSettingsTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap?.call();
        _toggleVisibility(); // Hide menu after selection
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReaderMenu(BuildContext context) {
    // Toggle the side menu overlay
    setState(() {
      // The overlay is controlled by _isVisible state
    });
  }

  void _onPageChanged(int targetPage) {
    // TODO: Implement page navigation through platform channel
    // This would require adding a jumpToPage method to ReaderProvider
    // ref.read(readerProvider.notifier).jumpToPage(targetPage);
    debugPrint('Navigate to page: $targetPage');
  }

  String _getTimeRemaining(double progress) {
    if (progress >= 1.0) return 'Complete';
    
    // Estimate based on average reading speed
    final remainingPercent = 1.0 - progress;
    final estimatedMinutes = (remainingPercent * 60).round(); // Rough estimate
    
    if (estimatedMinutes < 60) {
      return '${estimatedMinutes}m left';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      return '${hours}h ${minutes}m left';
    }
  }

  String _getReadingTime(int totalPages, int currentPage) {
    // Estimate reading time based on pages (rough calculation)
    final avgTimePerPage = 2; // minutes
    final totalTime = totalPages * avgTimePerPage;
    
    if (totalTime < 60) {
      return '${totalTime}m total';
    } else {
      final hours = totalTime ~/ 60;
      final minutes = totalTime % 60;
      return '${hours}h ${minutes}m total';
    }
  }
}