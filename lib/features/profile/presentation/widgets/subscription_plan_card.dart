import 'package:flutter/material.dart';

import '../../../../shared/models/subscription.dart';

/// Card displaying a subscription plan with features and pricing
class SubscriptionPlanCard extends StatefulWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.onSubscribe,
  });

  final SubscriptionPlan plan;
  final void Function(String billingCycle) onSubscribe;

  @override
  State<SubscriptionPlanCard> createState() => _SubscriptionPlanCardState();
}

class _SubscriptionPlanCardState extends State<SubscriptionPlanCard> {
  String _selectedCycle = 'monthly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = _selectedCycle == 'monthly'
        ? widget.plan.monthlyPrice
        : widget.plan.annualPrice;

    // Get first currency for display (in real app, use user's preferred currency)
    final currency = price.keys.first;
    final amount = price[currency] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan name and description
            Text(
              widget.plan.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.plan.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Billing cycle selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'monthly',
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: 'annual',
                  label: Text('Annual'),
                ),
              ],
              selected: {_selectedCycle},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedCycle = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Price display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$currency ${amount.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${_selectedCycle == 'monthly' ? 'month' : 'year'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Trial info
            if (widget.plan.trialDays > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  '${widget.plan.trialDays} days free trial',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Features list
            Text(
              'Features',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.plan.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onSubscribe(_selectedCycle),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
