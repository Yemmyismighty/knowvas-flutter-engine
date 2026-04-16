import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/knowvas_loading_spinner.dart';

/// Library book card matching React design
/// Shows book cover with progress, favorite button, and continue reading button
class LibraryBookCard extends StatefulWidget {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String genre;
  final double rating;
  final String reviews;
  final double? readingProgress;
  final bool isFinished;
  final bool isFavorite;
  final String? lastOpened;
  final String? purchaseDate;
  final int? currentPage;
  final int? totalPages;
  final String variant;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const LibraryBookCard({
    super.key,
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.genre,
    required this.rating,
    required this.reviews,
    this.readingProgress,
    this.isFinished = false,
    this.isFavorite = false,
    this.lastOpened,
    this.purchaseDate,
    this.currentPage,
    this.totalPages,
    this.variant = 'purchased',
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  State<LibraryBookCard> createState() => _LibraryBookCardState();
}

class _LibraryBookCardState extends State<LibraryBookCard> {
  bool _isHovered = false;

  Color _getProgressColor() {
    final progress = widget.readingProgress ?? 0;
    if (progress < 25) return Colors.red;
    if (progress < 50) return Colors.amber;
    if (progress < 75) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppTheme.brandPrimary.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover with Overlay
              _buildCover(),
              
              // Book Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.readingProgress != null && widget.readingProgress! > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${widget.readingProgress!.toInt()}% complete',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return Stack(
      children: [
        // Cover Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              key: ValueKey(widget.imageUrl),
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 320,
              memCacheHeight: 400,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: KnowvasPulseSpinner(size: 30),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.book, size: 40),
              ),
            ),
          ),
        ),

        // Hover Overlay
        if (_isHovered)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),

        // Status Badge
        if (widget.isFinished || widget.variant == 'currently-reading')
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isFinished ? Colors.green : AppTheme.brand600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isFinished)
                    const Icon(Icons.check_circle, size: 12, color: Colors.white),
                  if (widget.isFinished) const SizedBox(width: 4),
                  Text(
                    widget.isFinished ? 'Finished' : 'Reading',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Favorite Button
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: 8,
          left: 8,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isHovered ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: widget.onFavoriteToggle,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: widget.isFavorite ? Colors.red : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Continue Reading Button
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: _isHovered ? 8 : -40,
          left: 8,
          right: 8,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isHovered ? 1.0 : 0.0,
            child: ElevatedButton.icon(
              onPressed: widget.onTap,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text(
                widget.variant == 'currently-reading' ? 'Continue' : 'Start Reading',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
        ),

        // Progress Bar
        if (widget.readingProgress != null && widget.readingProgress! > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.readingProgress! / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getProgressColor(),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
