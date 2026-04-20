import 'package:flutter/material.dart';

import '../models/content.dart';
import 'content_card.dart';

/// Content carousel widget for displaying horizontal lists of content
class ContentCarousel extends StatefulWidget {
  const ContentCarousel({
    super.key,
    required this.title,
    required this.contents,
    this.onViewAll,
    this.onContentTap,
    this.size = ContentCardSize.medium,
  });

  final String title;
  final List<Content> contents;
  final VoidCallback? onViewAll;
  final Function(Content)? onContentTap;
  final ContentCardSize size;

  @override
  State<ContentCarousel> createState() => _ContentCarouselState();
}

class _ContentCarouselState extends State<ContentCarousel> {
  int? _flippedCardId;

  void _handleFlipRequest(int cardId) {
    setState(() {
      if (_flippedCardId == cardId) {
        _flippedCardId = null;
      } else {
        _flippedCardId = cardId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onViewAll != null)
                TextButton(
                  onPressed: widget.onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        // Content list
        SizedBox(
          height: _getCarouselHeight(),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.contents.length,
            itemBuilder: (context, index) {
              final content = widget.contents[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ContentCard(
                  key: ValueKey('content_${content.id}'),
                  id: content.id,
                  title: content.title,
                  type: content.type,
                  authorName: content.authorName,
                  price: content.price ?? {},
                  rating: content.averageRating,
                  reviews: '${content.reviewCount}',
                  genre: content.categories.isNotEmpty ? content.categories.first : 'General',
                  description: content.description,
                  imageUrl: content.coverUrl,
                  badges: const [],
                  size: widget.size,
                  isFree: content.isFree,
                  premiumOnly: content.premiumOnly,
                  isWishlisted: false,
                  isFlipped: _flippedCardId == content.id,
                  onFlipRequested: _handleFlipRequest,
                  onTap: () => widget.onContentTap?.call(content),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _getCarouselHeight() {
    switch (widget.size) {
      case ContentCardSize.small:  return 164; // 160 + 4
      case ContentCardSize.medium: return 212; // 208 + 4
      case ContentCardSize.large:  return 260; // 256 + 4
    }
  }
}
