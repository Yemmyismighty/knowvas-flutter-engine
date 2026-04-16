import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/cart_item.dart';
import '../providers/purchase_provider.dart';
import 'payment_method_selector.dart';

/// Dialog for confirming purchase
class PurchaseConfirmationDialog extends ConsumerStatefulWidget {
  const PurchaseConfirmationDialog({
    super.key,
    required this.items,
    required this.totalPrice,
    required this.currency,
    this.contentId,
  });

  final List<CartItem> items;
  final double totalPrice;
  final String currency;
  final int? contentId; // If provided, purchase single item; otherwise purchase cart

  @override
  ConsumerState<PurchaseConfirmationDialog> createState() =>
      _PurchaseConfirmationDialogState();
}

class _PurchaseConfirmationDialogState
    extends ConsumerState<PurchaseConfirmationDialog> {
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);

    return AlertDialog(
      title: const Text('Confirm Purchase'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...widget.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.content.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${widget.currency} ${item.content.price?[widget.currency]?.toStringAsFixed(2) ?? '0.00'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${widget.currency} ${widget.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment method selector
            PaymentMethodSelector(
              selectedMethod: _selectedPaymentMethod,
              onMethodSelected: (method) {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
            ),

            // Error message
            if (purchaseState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        purchaseState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: purchaseState.isProcessing
              ? null
              : () {
                  ref.read(purchaseProvider.notifier).clearMessages();
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: purchaseState.isProcessing || _selectedPaymentMethod == null
              ? null
              : () => _handlePurchase(),
          child: purchaseState.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Confirm Purchase'),
        ),
      ],
    );
  }

  Future<void> _handlePurchase() async {
    if (_selectedPaymentMethod == null) return;

    final notifier = ref.read(purchaseProvider.notifier);
    bool success;

    if (widget.contentId != null) {
      // Purchase single item
      success = await notifier.purchaseContent(
        contentId: widget.contentId!,
        currency: widget.currency,
        paymentMethod: _selectedPaymentMethod!,
      );
    } else {
      // Purchase entire cart
      success = await notifier.purchaseCart(
        currency: widget.currency,
        paymentMethod: _selectedPaymentMethod!,
      );
    }

    if (success && mounted) {
      // Clear messages and close dialog
      notifier.clearMessages();
      Navigator.of(context).pop(true);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(purchaseProvider).successMessage ??
                'Purchase completed successfully!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Helper function to show purchase confirmation dialog
Future<bool?> showPurchaseConfirmationDialog({
  required BuildContext context,
  required List<CartItem> items,
  required double totalPrice,
  required String currency,
  int? contentId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PurchaseConfirmationDialog(
      items: items,
      totalPrice: totalPrice,
      currency: currency,
      contentId: contentId,
    ),
  );
}
