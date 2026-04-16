import 'package:flutter/material.dart';

/// Payment method model
class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// Available payment methods
class PaymentMethods {
  static const List<PaymentMethod> methods = [
    PaymentMethod(
      id: 'card',
      name: 'Credit/Debit Card',
      description: 'Pay with your card',
      icon: Icons.credit_card,
    ),
    PaymentMethod(
      id: 'paypal',
      name: 'PayPal',
      description: 'Pay with PayPal',
      icon: Icons.account_balance_wallet,
    ),
    PaymentMethod(
      id: 'bank_transfer',
      name: 'Bank Transfer',
      description: 'Direct bank transfer',
      icon: Icons.account_balance,
    ),
  ];
}

/// Widget for selecting payment method
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  final String? selectedMethod;
  final ValueChanged<String> onMethodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...PaymentMethods.methods.map((method) {
          final isSelected = selectedMethod == method.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onMethodSelected(method.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      method.icon,
                      size: 32,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
