import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/cart_item.dart';

/// Cart item card matching web app design
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const CartItemCard({
    required this.item,
    required this.onRemove,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = item.content;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover
                Container(
                  width: 96,
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: content.cover != null && content.cover!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: content.cover!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.brand600, AppTheme.brand800],
                                ),
                              ),
                              child: const Icon(
                                Icons.book,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.brand600, AppTheme.brand800],
                              ),
                            ),
                            child: const Icon(
                              Icons.book,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Remove Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'by ${content.authorName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Genre Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brand100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    content.categories.isNotEmpty
                                        ? content.categories.first
                                        : content.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brand700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Remove Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red[500],
                            onPressed: onRemove,
                            tooltip: 'Remove from cart',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Price Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price per item
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatPrice(content.price),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          // Total price
                          Text(
                            _formatPrice(content.price),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brand600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(Map<String, double>? prices) {
    if (prices == null || prices.isEmpty) {
      return 'Free';
    }
    
    // Get the first available price (in production, use user's preferred currency)
    final currency = prices.keys.first;
    final price = prices[currency]!;
    
    return '$currency ${price.toStringAsFixed(2)}';
  }
}
