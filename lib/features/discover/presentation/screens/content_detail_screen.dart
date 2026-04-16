import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/download_manager_service.dart';
import '../../../../shared/models/content.dart';
import '../../../../shared/models/content_detail.dart';
import '../../../../shared/models/review.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/data/repositories/auth_repository_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/repositories/content_repository_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/content_carousel.dart';

/// Content detail screen displaying full information about a content item
/// Shows cover, title, author, rating, description, price, reviews, and similar content
/// Provides actions to add to cart, buy now, and preview (if available)
class ContentDetailScreen extends ConsumerStatefulWidget {
  const ContentDetailScreen({
    required this.contentId,
    super.key,
  });

  final int contentId;

  @override
  ConsumerState<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  final DownloadManagerService _downloadManager = DownloadManagerService();
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    // We'll check this after we have content type
  }

  @override
  Widget build(BuildContext context) {
    final contentDetailAsync = ref.watch(_contentDetailProvider(widget.contentId));
    final authState = ref.watch(authProvider);
    final preferredCurrency = authState.user?.preferredCurrency ?? 'NGN';

    return Scaffold(
      body: contentDetailAsync.when(
        data: (contentDetail) {
          // Check download status when content loads
          _checkDownloadStatusForContent(contentDetail.content);
          return _buildContent(
            context,
            ref,
            contentDetail,
            preferredCurrency,
          );
        },
        loading: () => const LoadingIndicator(
          message: 'Loading content details...',
        ),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(_contentDetailProvider(widget.contentId));
          },
        ),
      ),
    );
  }

  Future<void> _checkDownloadStatusForContent(Content content) async {
    final isDownloaded = await _downloadManager.isDownloaded(
      contentId: content.id.toString(),
      contentType: content.type,
    );
    
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ContentDetail contentDetail,
    String preferredCurrency,
  ) {
    final content = contentDetail.content;
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // App bar with cover image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Cover image
                if (content.coverUrl.isNotEmpty)
                  Image.network(
                    content.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.book,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.book,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  content.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Author
                InkWell(
                  onTap: () {
                    context.push('/discover/author/${content.authorId}');
                  },
                  child: Text(
                    'by ${content.authorName}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rating and metadata
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (content.ratingCount > 0)
                      _buildRatingChip(content.ratingAverage, content.ratingCount),
                    if (content.genres.isNotEmpty)
                      _buildChip(content.genres.first, Icons.category),
                    if (content.totalPages != null)
                      _buildChip('${content.totalPages} pages', Icons.menu_book),
                    if (content.language != null)
                      _buildChip(content.language!, Icons.language),
                  ],
                ),
                const SizedBox(height: 24),

                // Price and actions
                _buildPriceAndActions(
                  context,
                  ref,
                  content,
                  contentDetail,
                  preferredCurrency,
                ),
                const SizedBox(height: 32),

                // Description
                Text(
                  'About this ${content.type}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content.description ?? 'No description available',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // Additional info
                if (content.publisher != null || content.publishedDate != null)
                  _buildAdditionalInfo(content),

                // Reviews section
                if (contentDetail.reviews.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildReviewsSection(context, contentDetail),
                ],
              ],
            ),
          ),
        ),

        // Similar content carousel
        if (contentDetail.similarContent.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32, bottom: 24),
              child: ContentCarousel(
                title: 'Similar Content',
                content: contentDetail.similarContent,
                size: ContentCardSize.medium,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingChip(double rating, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($count)',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndActions(
    BuildContext context,
    WidgetRef ref,
    Content content,
    ContentDetail contentDetail,
    String preferredCurrency,
  ) {
    final theme = Theme.of(context);
    
    // Determine price display
    final String priceText;
    if (content.isFree) {
      priceText = 'Free';
    } else if (content.premiumOnly) {
      priceText = 'Premium Only';
    } else if (content.price?.containsKey(preferredCurrency) == true) {
      final price = content.price![preferredCurrency]!;
      final currencySymbol = _getCurrencySymbol(preferredCurrency);
      priceText = '$currencySymbol${price.toStringAsFixed(2)}';
    } else {
      priceText = 'Price not available';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price
        Row(
          children: [
            Text(
              priceText,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: content.isFree ? Colors.green : AppTheme.brandPrimary,
              ),
            ),
            if (contentDetail.isInLibrary) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'In Library',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            // Add to Cart / Read Now button
            Expanded(
              child: contentDetail.isInLibrary
                  ? FilledButton.icon(
                      onPressed: () {
                        context.push(
                          '/reader/${widget.contentId}?type=${content.type}',
                        );
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Read Now'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () {
                        _addToCart(context, ref, widget.contentId);
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Add to Cart'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Buy Now button (only if not in library)
            if (!contentDetail.isInLibrary)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _buyNow(context, ref, widget.contentId);
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Buy Now'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),

        // Preview button
        if (contentDetail.previewUrl != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _openPreview(context, contentDetail.previewUrl!);
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Preview'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],

        // Download button (only if in library)
        if (contentDetail.isInLibrary) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _isDownloading
                ? LinearProgressIndicator(
                    value: _downloadProgress,
                    minHeight: 48,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPrimary),
                  )
                : _isDownloaded
                    ? OutlinedButton.icon(
                        onPressed: () {
                          _deleteDownload(context, content);
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete Download', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () {
                          _downloadContent(context, content);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download for Offline Reading'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                      ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo(Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        if (content.publisher != null)
          _buildInfoRow('Publisher', content.publisher!),
        if (content.publishedDate != null)
          _buildInfoRow(
            'Published',
            content.publishedDate!,
          ),
        if (content.isbn != null) _buildInfoRow('ISBN', content.isbn!),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context, ContentDetail contentDetail) {
    final theme = Theme.of(context);
    final reviews = contentDetail.reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/content/${widget.contentId}/reviews');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...reviews.map(_buildReviewCard),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.profilePicture != null
                      ? NetworkImage(review.profilePicture!)
                      : null,
                  child: review.profilePicture == null
                      ? Text(review.username[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            review.createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.reviewText != null) ...[
              const SizedBox(height: 12),
              Text(
                review.reviewText!,
                style: const TextStyle(height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  (review.userLikeStatus == true)
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${review.likes}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'NGN':
        return '₦';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref, int contentId) async {
    final contentDetailAsync = ref.read(_contentDetailProvider(contentId));
    final contentType = contentDetailAsync.valueOrNull?.content.type ?? 'book';
    try {
      await ref.read(cartProvider.notifier).addToCart(contentId, resourceType: contentType);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _buyNow(BuildContext context, WidgetRef ref, int contentId) async {
    await _addToCart(context, ref, widget.contentId);
    if (context.mounted) {
      context.push('/cart');
    }
  }

  void _openPreview(BuildContext context, String previewUrl) {
    // TODO: Implement preview functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preview: $previewUrl'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadContent(BuildContext context, Content content) async {
    final authState = ref.read(authProvider);
    final token = authState.user?.id != null ? await ref.read(authRepositoryProvider).getAccessToken() : null;
    
    if (token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to download content')),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Determine file extension
      final fileExtension = (content.type == 'epub' || content.type == 'book') ? 'epub' : 'pdf';
      
      // Construct download URL
      final apiUrl = 'https://api.knowvas.com/api/contents/${content.id}/download';
      
      final success = await _downloadManager.downloadContent(
        contentId: content.id.toString(),
        contentType: content.type,
        apiUrl: apiUrl,
        authToken: token,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = success;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Downloaded successfully! You can now read offline.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Download failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDownload(BuildContext context, Content content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text('Are you sure you want to delete this downloaded content? You can download it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _downloadManager.deleteDownload(
          contentId: content.id.toString(),
          contentType: content.type,
        );

        if (mounted) {
          setState(() {
            _isDownloaded = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting download: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Provider for fetching content detail
final _contentDetailProvider = FutureProvider.family<ContentDetail, int>(
  (ref, contentId) async {
    final repository = ref.watch(contentRepositoryProvider);
    return repository.getContentDetail(contentId);
  },
);


