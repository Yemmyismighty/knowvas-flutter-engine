import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/cart_item.dart';
import '../../../../shared/models/content.dart';
import 'purchase_confirmation_dialog.dart';

/// Button for immediate purchase (Buy Now)
/// Bypasses cart and directly shows purchase confirmation
class BuyNowButton extends ConsumerWidget {
  const BuyNowButton({
    super.key,
    required this.content,
    required this.currency,
    this.onPurchaseComplete,
  });

  final Content content;
  final String currency;
  final VoidCallback? onPurchaseComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = content.price[currency] ?? 0.0;

    return FilledButton.icon(
      onPressed: () => _handleBuyNow(context),
      icon: const Icon(Icons.shopping_bag),
      label: Text('Buy Now - $currency ${price.toStringAsFixed(2)}'),
    );
  }

  Future<void> _handleBuyNow(BuildContext context) async {
    final price = content.price[currency] ?? 0.0;

    // Create a temporary cart item for the purchase dialog
    final cartItem = CartItem(
      content: content,
      addedAt: DateTime.now(),
    );

    // Show purchase confirmation dialog
    final result = await showPurchaseConfirmationDialog(
      context: context,
      items: [cartItem],
      totalPrice: price,
      currency: currency,
      contentId: content.id,
    );

    // If purchase was successful, notify parent
    if (result == true) {
      onPurchaseComplete?.call();
    }
  }
}
