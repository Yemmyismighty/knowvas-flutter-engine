import 'package:flutter/material.dart';

import '../../../../shared/models/content.dart';
import 'content_card.dart';

/// Horizontal carousel for displaying content with navigation arrows
class ContentCarousel extends StatefulWidget {
  const ContentCarousel({
    required this.title,
    required this.content,
    this.showViewAll = false,
    this.onViewAll,
    this.size = ContentCardSize.medium,
    super.key,
  });

  final String title;
  final List<Content> content;
  final bool showViewAll;
  final VoidCallback? onViewAll;
  final ContentCardSize size;

  @override
  State<ContentCarousel> createState() => _ContentCarouselState();
}

class _ContentCarouselState extends State<ContentCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtons();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!mounted) return;
    setState(() {
      _canScrollLeft = _scrollController.hasClients &&
          _scrollController.offset > 0;
      _canScrollRight = _scrollController.hasClients &&
          _scrollController.offset <
              _scrollController.position.maxScrollExtent - 1;
    });
  }

  void _scroll(bool left) {
    if (!_scrollController.hasClients) return;
    
    final scrollAmount = MediaQuery.of(context).size.width * 0.8;
    final targetOffset = left
        ? _scrollController.offset - scrollAmount
        : _scrollController.offset + scrollAmount;

    _scrollController.animateTo(
      targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.showViewAll)
                TextButton(
                  onPressed: widget.onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Carousel with navigation
        SizedBox(
          height: widget.size == ContentCardSize.small
              ? 200
              : widget.size == ContentCardSize.medium
                  ? 260
                  : 320,
          child: Stack(
            children: [
              // Scrollable content
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: widget.content.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return ContentCard(
                    content: widget.content[index],
                    size: widget.size,
                  );
                },
              ),
              // Left arrow
              if (_canScrollLeft)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _scroll(true),
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              // Right arrow
              if (_canScrollRight)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _scroll(false),
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

