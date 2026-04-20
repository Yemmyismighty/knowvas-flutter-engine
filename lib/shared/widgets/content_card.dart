import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import 'knowvas_loading_spinner.dart';

/// Flutter ContentCard — mirrors the web's flip card design exactly.
/// Front: book cover with glass badges.
/// Back: brand gradient with title, author, rating, price, actions.
/// On mobile, tap flips the card (no hover).
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

class _ContentCardState extends State<ContentCard> with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    if (widget.isFlipped) _flipCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(ContentCard old) {
    super.didUpdateWidget(old);
    if (widget.isFlipped != old.isFlipped) {
      widget.isFlipped ? _flipCtrl.forward() : _flipCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  // Web: small h-40 w-28 (160×112), medium h-52 w-36 (208×144), large h-64 w-44 (256×176)
  Size get _size {
    switch (widget.size) {
      case ContentCardSize.small:  return const Size(112, 160);
      case ContentCardSize.medium: return const Size(144, 208);
      case ContentCardSize.large:  return const Size(176, 256);
    }
  }

  double get _backPad => widget.size == ContentCardSize.small ? 10 : 16;

  IconData get _typeIcon {
    switch (widget.type) {
      case 'audiobook':   return Icons.headphones_outlined;
      case 'magazine':    return Icons.newspaper_outlined;
      case 'comics':      return Icons.auto_stories_outlined;
      case 'newspapers':  return Icons.newspaper_outlined;
      default:            return Icons.menu_book_outlined;
    }
  }

  String get _typeLabel {
    switch (widget.type) {
      case 'audiobook':  return 'Audiobook';
      case 'magazine':   return 'Magazine';
      case 'comics':     return 'Comic';
      case 'newspapers': return 'Newspaper';
      default:           return 'Book';
    }
  }

  String get _priceLabel {
    if (widget.premiumOnly) return 'Members';
    if (widget.isFree) return 'Free';
    final ngn = widget.price['NGN'];
    if (ngn == null || ngn == 0) return 'Free';
    final n = (ngn as num).toInt();
    if (n >= 1000) return '₦${(n / 1000).toStringAsFixed(0)}k';
    return '₦$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onFlipRequested?.call(widget.id),
      child: SizedBox(
        width: _size.width,
        height: _size.height,
        child: AnimatedBuilder(
          animation: _flipAnim,
          builder: (_, __) {
            final showFront = _flipAnim.value < 0.5;
            // Mirror the card when showing back so text isn't reversed
            final angle = _flipAnim.value * 3.14159;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showFront ? _front() : Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(3.14159),
                child: _back(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── FRONT ────────────────────────────────────────────────────────────────

  Widget _front() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[200],
                child: const Center(child: KnowvasPulseSpinner(size: 32)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.brand100,
                child: const Center(child: Icon(Icons.menu_book, color: AppTheme.brand400, size: 36)),
              ),
            ),

            // Subtle bottom gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.15)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Top-right badges stack
            Positioned(
              top: 6,
              right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Content type — glass badge
                  _glassBadge(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon, color: Colors.white, size: 10),
                        if (widget.size != ContentCardSize.small) ...[
                          const SizedBox(width: 3),
                          Text(_typeLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Free badge
                  if (widget.isFree && !widget.premiumOnly)
                    _colorBadge('Free', Colors.green[600]!),
                  // Premium badge
                  if (widget.premiumOnly)
                    _premiumBadge(),
                  // Extra badges
                  ...widget.badges.map((b) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _colorBadge(b.text, _badgeColor(b.variant)),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassBadge({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.brand500.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _colorBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  Widget _premiumBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.5), blurRadius: 6)],
      ),
      child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 10),
    );
  }

  Color _badgeColor(BadgeVariant v) {
    switch (v) {
      case BadgeVariant.bestseller: return Colors.orange;
      case BadgeVariant.featured:   return AppTheme.brand600;
      case BadgeVariant.newBadge:   return Colors.green;
      case BadgeVariant.trending:   return Colors.blue;
    }
  }

  // ─── BACK ─────────────────────────────────────────────────────────────────

  Widget _back() {
    final pad = _backPad;
    final isSmall = widget.size == ContentCardSize.small;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brand500, AppTheme.brand700],
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.brand600.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (scrollable content) ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.genre,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isSmall ? 4 : 6),

                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 2 : 4),

                // Author
                Text(
                  'by ${widget.authorName}',
                  style: TextStyle(color: AppTheme.brand100, fontSize: isSmall ? 9 : 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 4 : 6),

                // Stars + rating
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(
                      i < widget.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: isSmall ? 9 : 10,
                    )),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        widget.rating > 0 ? widget.rating.toStringAsFixed(1) : '',
                        style: TextStyle(color: AppTheme.brand100, fontSize: 9),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          SizedBox(height: isSmall ? 6 : 8),

          // Price row + icon buttons
          Row(
            children: [
              Expanded(
                child: Text(
                  _priceLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 11 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Wishlist
              _iconBtn(
                icon: widget.isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: widget.isWishlisted ? Colors.red[300]! : Colors.white,
                onTap: widget.onWishlistToggle,
                size: isSmall ? 14 : 15,
              ),
              const SizedBox(width: 2),
              // Details
              _iconBtn(
                icon: Icons.menu_book_outlined,
                color: Colors.white,
                onTap: widget.onTap,
                size: isSmall ? 14 : 15,
              ),
            ],
          ),

          SizedBox(height: isSmall ? 6 : 8),

          // Action button
          SizedBox(
            width: double.infinity,
            height: isSmall ? 24 : 28,
            child: ElevatedButton(
              onPressed: widget.isFree || widget.premiumOnly ? widget.onTap : widget.onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.brand600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isFree || widget.premiumOnly ? Icons.menu_book_outlined : Icons.shopping_cart_outlined,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.isFree || widget.premiumOnly
                          ? 'Details'
                          : isSmall ? 'Cart' : 'Add to Cart',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required Color color, VoidCallback? onTap, double size = 14}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

// ─── Supporting types ──────────────────────────────────────────────────────

enum ContentCardSize { small, medium, large }
enum BadgeVariant { bestseller, featured, newBadge, trending }

class ContentBadge {
  final String text;
  final BadgeVariant variant;
  const ContentBadge({required this.text, required this.variant});
}
