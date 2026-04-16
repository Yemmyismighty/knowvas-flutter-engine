import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/cart_state.dart';
import '../widgets/purchase_confirmation_dialog.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/order_summary_card.dart';

/// Cart screen matching web app design
/// Displays cart items with cover, title, author, price
/// Allows removing items and proceeding to checkout
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.95),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              Colors.white,
            ],
          ),
        ),
        child: _buildBody(context, cartState, cartNotifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CartState cartState,
    Cart cartNotifier,
  ) {
    // Show loading indicator on initial load
    if (cartState.isLoading && !cartState.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error message if there's an error and no items
    if (cartState.error != null && cartState.isEmpty) {
      return _buildErrorState(context, cartState.error!, cartNotifier);
    }

    // Show empty cart state
    if (cartState.isEmpty) {
      return _buildEmptyState(context);
    }

    // Show cart items with order summary
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Shopping Cart',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${cartState.itemCount} ${cartState.itemCount == 1 ? 'item' : 'items'} in your cart',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Error banner if there's an error
            if (cartState.error != null) ...[
              _buildErrorBanner(context, cartState.error!, cartNotifier),
              const SizedBox(height: 24),
            ],
            
            // Layout for larger screens
            LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 900;
                
                if (isLargeScreen) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Items (2/3 width)
                      Expanded(
                        flex: 2,
                        child: _buildCartItemsList(context, cartState, cartNotifier),
                      ),
                      const SizedBox(width: 32),
                      // Order Summary (1/3 width)
                      Expanded(
                        flex: 1,
                        child: OrderSummaryCard(
                          itemCount: cartState.itemCount,
                          totalPrice: cartState.totalPrice,
                          isLoading: cartState.isLoading,
                          onCheckout: () => _handleCheckout(context, cartNotifier),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildCartItemsList(context, cartState, cartNotifier),
                      const SizedBox(height: 24),
                      OrderSummaryCard(
                        itemCount: cartState.itemCount,
                        totalPrice: cartState.totalPrice,
                        isLoading: cartState.isLoading,
                        onCheckout: () => _handleCheckout(context, cartNotifier),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList(
    BuildContext context,
    CartState cartState,
    Cart cartNotifier,
  ) {
    return Column(
      children: [
        // Cart Items
        ...cartState.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CartItemCard(
                item: item,
                onRemove: () => _showRemoveItemDialog(
                  context,
                  item.content.id,
                  item.content.title,
                  cartNotifier,
                ),
                onTap: () => context.push('/content/${item.content.id}'),
              ),
            )),
        
        // Clear Cart Button
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _showClearCartDialog(context, cartNotifier),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear Cart'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[200]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Looks like you haven\'t added any books to your cart yet. Start exploring our collection!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.brand600, AppTheme.brand700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.push('/discover'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Discover Books',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String error,
    Cart cartNotifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load cart',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => cartNotifier.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    String error,
    Cart cartNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: Colors.red[700],
            onPressed: () => cartNotifier.clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    Cart cartNotifier,
  ) {
    final content = item.content;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to content detail screen
          // TODO: Implement navigation when content detail screen is available
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: content.cover ?? '',
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 120,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 120,
                    color: theme.colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.book,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      content.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      content.authorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        content.type.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price
                    _buildPriceDisplay(context, content.price ?? {}),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
                onPressed: () => _showRemoveItemDialog(
                  context,
                  content.id,
                  content.title,
                  cartNotifier,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(
    BuildContext context,
    Map<String, double> prices,
  ) {
    final theme = Theme.of(context);

    // Get the first available price (in production, use user's preferred currency)
    if (prices.isEmpty) {
      return Text(
        'Free',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final currency = prices.keys.first;
    final price = prices[currency]!;

    return Text(
      '$currency ${price.toStringAsFixed(2)}',
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCheckoutSection(
    BuildContext context,
    CartState cartState,
    Cart cartNotifier,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTotalPrice(context, cartState.totalPrice),
              ],
            ),
            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cartState.isLoading
                    ? null
                    : () => _handleCheckout(context, cartNotifier),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: cartState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Proceed to Checkout',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPrice(
    BuildContext context,
    Map<String, double> totalPrices,
  ) {
    final theme = Theme.of(context);

    if (totalPrices.isEmpty) {
      return Text(
        'Free',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Display all currencies (in production, show only user's preferred currency)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: totalPrices.entries.map((entry) {
        return Text(
          '${entry.key} ${entry.value.toStringAsFixed(2)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList(),
    );
  }

  void _showRemoveItemDialog(
    BuildContext context,
    int contentId,
    String title,
    Cart cartNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "$title" from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              cartNotifier.removeFromCart(contentId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, Cart cartNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              cartNotifier.clearCart();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, Cart cartNotifier) async {
    final cartState = cartNotifier.state;
    
    if (cartState.isEmpty) {
      return;
    }

    // Get the first currency from total price (in production, use user's preferred currency)
    final currency = cartState.totalPrice.keys.first;
    final totalPrice = cartState.totalPrice[currency] ?? 0.0;

    // Show purchase confirmation dialog
    final result = await showPurchaseConfirmationDialog(
      context: context,
      items: cartState.items,
      totalPrice: totalPrice,
      currency: currency,
    );

    // If purchase was successful, show success message
    if (result == true && context.mounted) {
      // Cart is already cleared by the purchase provider
      // Just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Items added to your library!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View Library',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to library
              // TODO: Implement navigation to library when available
            },
          ),
        ),
      );
    }
  }
}
