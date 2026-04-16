import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/platform/reader_channel.dart';
import '../../../../core/platform/reader_dtos.dart';
import '../../../../shared/widgets/knowvas_loading_spinner.dart';
import '../../../../shared/widgets/content_carousel.dart';
import '../../../../shared/widgets/wishlist_button.dart';
import '../../../../shared/widgets/review_modal.dart';
import '../../../../shared/models/content.dart';
import '../../../../shared/models/content_detail.dart';
import '../providers/content_details_provider.dart';
import '../../../discover/data/repositories/content_repository_provider.dart';
import '../../../reader/presentation/screens/screens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/wishlist_repository_provider.dart';
import '../../data/repositories/follow_repository_provider.dart';
import '../../data/repositories/cart_repository_provider.dart';
import '../../data/repositories/review_repository_provider.dart';
import '../../domain/content_access_logic.dart';

/// Content details screen matching the React app design
class ContentDetailsScreen extends ConsumerStatefulWidget {
  final String contentId;

  const ContentDetailsScreen({
    required this.contentId,
    super.key,
  });

  @override
  ConsumerState<ContentDetailsScreen> createState() => _ContentDetailsScreenState();
}

class _ContentDetailsScreenState extends ConsumerState<ContentDetailsScreen> {
  final ReaderChannel _readerChannel = ReaderChannel();
  bool _isOpeningReader = false;
  bool _wishlistLoading = false;
  bool _followLoading = false;
  bool _cartLoading = false;
  bool _reviewLoading = false;
  bool _isWishlisted = false;
  bool _isFollowing = false;
  int _followersCount = 0;

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentDetailsProvider(widget.contentId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: contentState.when(
        data: (contentDetail) => _buildContent(context, contentDetail),
        loading: () => const Center(child: KnowvasLoadingSpinner(size: 80)),
        error: (error, stack) => _buildError(context, error.toString()),
      ),

    );
  }

  Widget _buildContent(BuildContext context, ContentDetail contentDetail) {
    final content = contentDetail.content;
    
    // Initialize state from content detail
    if (_followersCount == 0 && contentDetail.authorInfo != null) {
      _followersCount = contentDetail.authorInfo!.followersCount;
      _isFollowing = contentDetail.authorInfo!.isFollowing;
    }
    if (!_isWishlisted && contentDetail.isWishlisted != null) {
      _isWishlisted = contentDetail.isWishlisted!;
    }
    
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          pinned: true,
          backgroundColor: Colors.white.withOpacity(0.8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WishlistButton(
                isWishlisted: _isWishlisted,
                isLoading: _wishlistLoading,
                onToggle: () => _handleWishlistToggle(content),
                size: 24,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black87),
              onPressed: () => _handleShare(content),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                
                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Book Cover
                      Expanded(
                        flex: 1,
                        child: _buildCoverSection(context, content),
                      ),
                      const SizedBox(width: 48),
                      // Right: Book Information
                      Expanded(
                        flex: 1,
                        child: _buildInfoSection(context, content, contentDetail),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildCoverSection(context, content),
                      const SizedBox(height: 32),
                      _buildInfoSection(context, content, contentDetail),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverSection(BuildContext context, Content content) {
    final user = ref.watch(authProvider).user;
    
    // Get content detail to extract access info
    final contentState = ref.watch(contentDetailsProvider(widget.contentId));
    final contentDetail = contentState.maybeWhen(
      data: (detail) => detail,
      orElse: () => null,
    );
    
    // Determine access state
    final accessInfo = _buildAccessInfo(content, contentDetail);
    final accessState = ContentAccessLogic.determineAccess(
      user: user,
      content: accessInfo,
    );
    
    return Column(
      children: [
        // Book Cover with glow effect
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
              children: [
                // Glow effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandPrimary.withOpacity(0.2),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                // Cover image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandPrimary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: content.cover != null && content.cover!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: content.cover!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.center,
                            fadeInDuration: const Duration(milliseconds: 200),
                            fadeOutDuration: const Duration(milliseconds: 100),
                            memCacheWidth: 600,
                            memCacheHeight: 800,
                            placeholder: (context, url) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: KnowvasPulseSpinner(size: 50),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.brand600,
                                    AppTheme.brand800,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.book,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.brand600,
                                  AppTheme.brand800,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.book,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                // Bestseller badge (if applicable)
                if (content.averageRating >= 4.5)
                  Positioned(
                    top: -12,
                    right: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.emoji_events, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Bestseller',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
        
        const SizedBox(height: 32),
        
        // Quick Actions
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
            children: [
              // Primary action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isOpeningReader ? null : () => _handleReadButton(content),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand600,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.brandPrimary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isOpeningReader
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          content.isFree
                              ? 'Read Now - Free'
                              : 'Read Now - \$${content.price?['NGN']?.toStringAsFixed(2) ?? '12.99'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Secondary actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePreview(content),
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Preview'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brand600,
                        side: BorderSide(color: AppTheme.brand200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cartLoading ? null : () => _handleAddToCart(content),
                      icon: _cartLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_cart, size: 18),
                      label: const Text('Add to Cart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brand600,
                        side: BorderSide(color: AppTheme.brand200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Content content, ContentDetail contentDetail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (content.categories.isNotEmpty)
              _buildBadge(
                content.categories.first,
                AppTheme.brand100,
                AppTheme.brand700,
              ),
            if (content.year != null && content.year! >= DateTime.now().year)
              _buildBadge(
                'New Release',
                Colors.green[100]!,
                Colors.green[700]!,
                outlined: true,
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Title
        Text(
          content.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
        ),
        
        const SizedBox(height: 12),
        
        // Description preview
        if (content.description != null)
          Text(
            content.description!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        
        const SizedBox(height: 24),
        
        // Author info
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.brand600, AppTheme.brand700],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  content.authorName.isNotEmpty
                      ? content.authorName.substring(0, 1).toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (content.authorId != null) {
                        context.push('/creator/${content.authorId}');
                      }
                    },
                    child: Text(
                      content.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brand600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '$_followersCount followers',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (ref.watch(authProvider).user != null)
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _followLoading ? null : () => _handleFollowToggle(contentDetail),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.white : AppTheme.brand600,
                    foregroundColor: _isFollowing ? AppTheme.brand600 : Colors.white,
                    side: _isFollowing ? BorderSide(color: AppTheme.brand200) : null,
                    elevation: _isFollowing ? 0 : 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _followLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(fontSize: 14),
                        ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Rating
        Row(
          children: [
            ...List.generate(
              5,
              (index) => Icon(
                index < content.averageRating.floor()
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              content.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${content.reviewCount} reviews)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Book Details Card
        _buildDetailsCard(context, content),
        
        const SizedBox(height: 32),
        
        // About This Book
        _buildAboutSection(context, content),
        
        const SizedBox(height: 32),
        
        // Reviews Preview
        _buildReviewsSection(context, contentDetail),
        
        const SizedBox(height: 48),
        
        // Similar Content Carousel
        if (contentDetail.similarContent.isNotEmpty) ...[
          ContentCarousel(
            title: 'Similar Content',
            contents: contentDetail.similarContent,
            onContentTap: (content) {
              context.push('/content/${content.id}');
            },
          ),
          const SizedBox(height: 32),
        ],
        
        // More by Author Carousel
        FutureBuilder<List<Content>>(
          future: _fetchMoreByAuthor(content.authorId, content.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return ContentCarousel(
              title: 'More by ${content.authorName}',
              contents: snapshot.data!,
              onContentTap: (content) {
                context.push('/content/${content.id}');
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bgColor,
        border: outlined ? Border.all(color: bgColor) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Content content) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.access_time,
            'Reading Time:',
            content.estimatedReadTime != null
                ? '${(content.estimatedReadTime! / 60).toStringAsFixed(1)}h'
                : 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.menu_book,
            'Type:',
            content.type.toUpperCase(),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.people,
            'Readers:',
            '${(content.ratingCount / 1000).toStringAsFixed(1)}k',
          ),
          if (content.language != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.language,
              'Language:',
              content.language!.toUpperCase(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.brand600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Book',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          content.description ?? 'No description available.',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, ContentDetail contentDetail) {
    // Use actual reviews if available, otherwise show mock reviews
    final hasReviews = contentDetail.reviews.isNotEmpty;
    final reviews = hasReviews 
        ? contentDetail.reviews.take(3).toList()
        : null;
    
    // Mock reviews as fallback
    final mockReviews = [
      {'name': 'Sarah M.', 'rating': 5, 'comment': 'Absolutely mind-blowing! A masterpiece that will stay with you long after the last page.'},
      {'name': 'David L.', 'rating': 5, 'comment': 'The perfect blend of storytelling. Couldn\'t put it down!'},
      {'name': 'Emma K.', 'rating': 4, 'comment': 'Complex and beautiful. Highly recommended!'},
    ];

    final user = ref.watch(authProvider).user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'What Readers Are Saying',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (user != null)
              TextButton.icon(
                onPressed: () => _showReviewModal(contentDetail.content),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Write Review'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.brand600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasReviews)
          ...reviews!.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                review.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...List.generate(
                                review.rating.floor(),
                                (index) => const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          if (user != null)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                                  onPressed: () => _handleReviewLike(review.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${review.likes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.thumb_down_outlined, size: 16),
                                  onPressed: () => _handleReviewDislike(review.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${review.dislikes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review.reviewText ?? '',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
        else
          ...mockReviews.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(
                            review['rating'] as int,
                            (index) => const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['comment'] as String,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        TextButton(
          onPressed: () {
            // TODO: Show all reviews
          },
          child: const Text('Read All Reviews'),
        ),
      ],
    );
  }

  Future<List<Content>> _fetchMoreByAuthor(int? authorId, int currentContentId) async {
    if (authorId == null) return [];
    
    try {
      // Use the content repository to search for content by this author
      final repository = ref.read(contentRepositoryProvider);
      final searchResult = await repository.searchContent(
        filters: {'author_id': authorId.toString()},
        page: 1,
        limit: 6,
      );
      
      // Filter out the current content
      return searchResult.results.where((c) => c.id != currentContentId).toList();
    } catch (e) {
      return [];
    }
  }

  /// Handle wishlist toggle
  Future<void> _handleWishlistToggle(Content content) async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      context.push('/auth/signin');
      return;
    }

    setState(() => _wishlistLoading = true);

    try {
      final repository = ref.read(wishlistRepositoryProvider);
      final result = await repository.toggleWishlist(
        resourceId: content.id,
        resourceType: content.type,
      );

      setState(() {
        _isWishlisted = result.isWishlisted;
        _wishlistLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.action == 'added'
                  ? 'Added to wishlist'
                  : 'Removed from wishlist',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: result.action == 'added' ? Colors.green : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      setState(() => _wishlistLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wishlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle follow/unfollow author
  Future<void> _handleFollowToggle(ContentDetail contentDetail) async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      context.push('/auth/signin');
      return;
    }

    if (contentDetail.content.authorId == null) return;

    setState(() => _followLoading = true);

    try {
      final repository = ref.read(followRepositoryProvider);
      final result = await repository.toggleFollow(
        followableType: 'author',
        followableId: contentDetail.content.authorId!,
        isCurrentlyFollowing: _isFollowing,
      );

      setState(() {
        _isFollowing = result.isFollowing;
        _followersCount = result.followersCount;
        _followLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _followLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle add to cart
  Future<void> _handleAddToCart(Content content) async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      context.push('/auth/signin');
      return;
    }

    setState(() => _cartLoading = true);

    try {
      final repository = ref.read(cartRepositoryProvider);
      final result = await repository.addToCart(
        resourceId: content.id,
        resourceType: content.type,
        quantity: 1,
      );

      setState(() => _cartLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _cartLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle share
  void _handleShare(Content content) {
    // TODO: Implement native share
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: ${content.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle preview
  void _handlePreview(Content content) {
    // TODO: Open preview mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview mode coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Handles the read button click - routes to appropriate reader based on content type
  Future<void> _handleReadButton(Content content) async {
    setState(() {
      _isOpeningReader = true;
    });

    try {
      final contentType = content.type.toLowerCase();
      
      // Route based on content type
      if (contentType == 'book') {
        // Open EPUB reader for books
        await _openEpubReader(content);
      } else if (contentType == 'comic' || contentType == 'magazine' || contentType == 'newspaper') {
        // Open PDF reader for comics, magazines, and newspapers
        await _openPdfReader(content);
      } else if (contentType == 'audiobook') {
        // Open audiobook player
        await _openAudiobookPlayer(content);
      } else {
        // Unknown content type
        throw Exception('Unsupported content type: ${content.type}');
      }
    } catch (e) {
      setState(() {
        _isOpeningReader = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open reader: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Opens EPUB reader for books
  Future<void> _openEpubReader(Content content) async {
    try {
      // Copy sample EPUB from assets to local storage
      final ByteData data = await rootBundle.load('assets/sample.epub');
      final List<int> bytes = data.buffer.asUint8List();
      
      // Get app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localPath = '${appDocDir.path}/sample.epub';
      final File localFile = File(localPath);
      
      // Write the EPUB file
      await localFile.writeAsBytes(bytes);

      // Open the reader with the local file
      final request = OpenReaderRequest(
        contentId: content.id,
        type: 'epub',
        fileUrl: localPath,
        token: '', // Empty token for local files
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await _readerChannel.openReader(request);

      setState(() {
        _isOpeningReader = false;
      });

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('EPUB reader opened successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.errorMessage ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isOpeningReader = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open EPUB reader: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Opens PDF reader for comics, magazines, and newspapers
  Future<void> _openPdfReader(Content content) async {
    try {
      // Copy sample PDF from assets to local storage
      final ByteData data = await rootBundle.load('assets/sample.pdf');
      final List<int> bytes = data.buffer.asUint8List();
      
      // Get app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localPath = '${appDocDir.path}/sample.pdf';
      final File localFile = File(localPath);
      
      // Write the PDF file
      await localFile.writeAsBytes(bytes);

      // Open the reader with the local file
      final request = OpenReaderRequest(
        contentId: content.id,
        type: 'pdf',
        fileUrl: localPath,
        token: '', // Empty token for local files
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await _readerChannel.openReader(request);

      setState(() {
        _isOpeningReader = false;
      });

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF reader opened successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.errorMessage ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isOpeningReader = false;
      });
      rethrow;
    }
  }

  /// Opens audiobook player
  Future<void> _openAudiobookPlayer(Content content) async {
    setState(() {
      _isOpeningReader = false;
    });

    if (mounted) {
      // Navigate to audiobook player screen
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => AudiobookPlayerScreen(
            contentId: content.id,
            contentTitle: content.title,
          ),
        ),
      );
    }
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build access info from content and content detail
  ContentAccessInfo _buildAccessInfo(Content content, ContentDetail? contentDetail) {
    return ContentAccessInfo(
      type: content.type,
      fileType: content.fileType,
      isFree: content.isFree,
      isPurchased: contentDetail?.isPurchased ?? false,
      isPremiumOnly: contentDetail?.isPremiumOnly ?? false,
      isPurchaseOnly: contentDetail?.isPurchaseOnly ?? false,
      price: content.price?['NGN']?.toDouble() ?? 0.0,
      withinFreeLimit: contentDetail?.withinFreeLimit,
      withinNonFreeLimit: contentDetail?.withinNonFreeLimit,
      userSubscriptionTier: contentDetail?.userSubscriptionTier,
    );
  }

  /// Get primary button color based on button state
  Color _getPrimaryButtonColor(ButtonState state) {
    switch (state) {
      case ButtonState.read:
        return AppTheme.brand600;
      case ButtonState.purchase:
        return Colors.green[600]!;
      case ButtonState.subscribe:
      case ButtonState.upgrade:
        return const Color(0xFFFFD700);
      case ButtonState.loginRequired:
        return Colors.grey[600]!;
    }
  }

  /// Handle primary action button
  Future<void> _handlePrimaryAction(Content content, ContentAccessState accessState) async {
    switch (accessState.buttonState) {
      case ButtonState.read:
        await _handleReadButton(content);
        break;
      case ButtonState.purchase:
        await _handlePurchase(content);
        break;
      case ButtonState.subscribe:
      case ButtonState.upgrade:
        await _handleSubscribe();
        break;
      case ButtonState.loginRequired:
        context.push('/auth/signin');
        break;
    }
  }

  /// Handle purchase
  Future<void> _handlePurchase(Content content) async {
    // Navigate to checkout or show purchase dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Purchase: ${content.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle subscribe/upgrade
  Future<void> _handleSubscribe() async {
    // Navigate to subscription page
    context.push('/subscription');
  }

  /// Show review modal
  void _showReviewModal(Content content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewModal(
        isLoading: _reviewLoading,
        onSubmit: (rating, reviewText) async {
          await _submitReview(content, rating, reviewText);
        },
      ),
    );
  }

  /// Submit review
  Future<void> _submitReview(Content content, int rating, String reviewText) async {
    setState(() => _reviewLoading = true);

    try {
      final repository = ref.read(reviewRepositoryProvider);
      final result = await repository.submitReview(
        resourceId: content.id,
        resourceType: content.type,
        reviewText: reviewText,
        rating: rating,
      );

      setState(() => _reviewLoading = false);

      if (mounted) {
        Navigator.of(context).pop(); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Refresh content details to show new review
        ref.invalidate(contentDetailsProvider(widget.contentId));
      }
    } catch (e) {
      setState(() => _reviewLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle review like
  Future<void> _handleReviewLike(int reviewId) async {
    try {
      final repository = ref.read(reviewRepositoryProvider);
      await repository.likeReview(reviewId);
      
      // Refresh content details to update like counts
      ref.invalidate(contentDetailsProvider(widget.contentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle review dislike
  Future<void> _handleReviewDislike(int reviewId) async {
    try {
      final repository = ref.read(reviewRepositoryProvider);
      await repository.dislikeReview(reviewId);
      
      // Refresh content details to update dislike counts
      ref.invalidate(contentDetailsProvider(widget.contentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to dislike review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
