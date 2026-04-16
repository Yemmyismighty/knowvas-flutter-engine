import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import 'knowvas_loading_spinner.dart';

/// Flutter widget that exactly mirrors the React ContentCard component
class ContentCard extends StatefulWidget {
  final int id;
  final String title;
  final String type;
  final String authorName;
  final Map<String, dynamic> price;
  final double rating;
  final String reviews;
  final String genre;
  final String? description;
  final String imageUrl;
  final List<ContentBadge> badges;
  final ContentCardSize size;
  final bool isFree;
  final bool premiumOnly;
  final bool isWishlisted;
  final bool isFlipped;
  final ValueChanged<int>? onFlipRequested;
  final VoidCallback? onWishlistToggle;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;

  const ContentCard({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    required this.authorName,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.genre,
    this.description,
    required this.imageUrl,
    this.badges = const [],
    this.size = ContentCardSize.medium,
    this.isFree = false,
    this.premiumOnly = false,
    this.isWishlisted = false,
    this.isFlipped = false,
    this.onFlipRequested,
    this.onWishlistToggle,
    this.onAddToCart,
    this.onTap,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _flipController;
  late AnimationController _wishlistController;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _wishlistController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _wishlistController,
      curve: Curves.elasticOut,
    ));

    // Set initial flip state
    if (widget.isFlipped) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Respond to external flip state changes
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _wishlistController.dispose();
    super.dispose();
  }

  // Exact dimensions matching React Tailwind classes
  Size get _cardSize {
    switch (widget.size) {
      case ContentCardSize.small:
        return const Size(144, 192); // w-36 h-48 (36*4=144, 48*4=192)
      case ContentCardSize.medium:
        return const Size(192, 256); // w-48 h-64
      case ContentCardSize.large:
        return const Size(240, 320); // w-60 h-80
    }
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    // Only auto-flip on hover if not already flipped by tap
    if (!widget.isFlipped) {
      if (isHovered) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  void _handleTap() {
    // Notify parent to flip this card (and unflip others)
    if (widget.onFlipRequested != null) {
      widget.onFlipRequested!(widget.id);
    }
  }

  void _handleWishlistToggle() {
    if (widget.onWishlistToggle != null) {
      _wishlistController.forward().then((_) {
        _wishlistController.reverse();
      });
      widget.onWishlistToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: _handleTap,
        child: SizedBox(
          width: _cardSize.width,
          height: _cardSize.height,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final isShowingFront = _flipAnimation.value < 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(_flipAnimation.value * 3.14159),
                child: isShowingFront ? _buildFrontSide() : _buildBackSide(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (_isHovered)
            BoxShadow(
              color: AppTheme.brandPrimary.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Book cover image
            Positioned.fill(
              child: CachedNetworkImage(
                key: ValueKey(widget.imageUrl),
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 400, // Optimize memory usage
                memCacheHeight: 600,
                maxWidthDiskCache: 800,
                maxHeightDiskCache: 1200,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: KnowvasPulseSpinner(size: 40),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, size: 48),
                ),
              ),
            ),
            
            // Hover overlay
            if (_isHovered)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),

            // Badges
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.badges.map((badge) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildBadge(badge),
                  ),
                ).toList(),
              ),
            ),

            // Free badge
            if (widget.isFree)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    'Free',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159), // Flip back to normal
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brand500,
              AppTheme.brand700,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPrimary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genre badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.genre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Title
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),
            
            // Author
            Text(
              'by ${widget.authorName}',
              style: TextStyle(
                color: AppTheme.brand100,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            
            const SizedBox(height: 8),
            
            // Rating
            Row(
              children: [
                ...List.generate(5, (index) => Icon(
                  index < widget.rating.floor() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 11,
                )),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${widget.rating} (${widget.reviews})',
                    style: TextStyle(
                      color: AppTheme.brand100,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Price and actions
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.premiumOnly 
                        ? 'Membership'
                        : widget.isFree 
                            ? 'Free'
                            : '\$${widget.price['NGN'] ?? '0.00'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.premiumOnly || widget.isFree ? 11 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                // Wishlist button
                SizedBox(
                  width: 28,
                  height: 28,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    child: IconButton(
                      onPressed: _handleWishlistToggle,
                      icon: Icon(
                        widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: widget.isWishlisted ? Colors.red : Colors.white,
                        size: 14,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    builder: (context, child) => Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  ),
                ),
                
                // Details button
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: widget.onTap,
                    icon: const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 14,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Action button
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                onPressed: widget.isFree || widget.premiumOnly 
                    ? widget.onTap 
                    : widget.onAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.brand600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isFree || widget.premiumOnly 
                            ? Icons.menu_book 
                            : Icons.shopping_cart,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isFree || widget.premiumOnly ? 'Details' : 'Add to Cart',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ContentBadge badge) {
    Color backgroundColor;
    switch (badge.variant) {
      case BadgeVariant.bestseller:
        backgroundColor = Colors.orange;
        break;
      case BadgeVariant.featured:
        backgroundColor = AppTheme.brand600;
        break;
      case BadgeVariant.newBadge:
        backgroundColor = Colors.green;
        break;
      case BadgeVariant.trending:
        backgroundColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badge.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Supporting classes
enum ContentCardSize { small, medium, large }

enum BadgeVariant { bestseller, featured, newBadge, trending }

class ContentBadge {
  final String text;
  final BadgeVariant variant;

  const ContentBadge({
    required this.text,
    required this.variant,
  });
}
