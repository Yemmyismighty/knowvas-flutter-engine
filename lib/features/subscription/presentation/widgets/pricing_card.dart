import 'package:flutter/material.dart';
import 'package:knowvas/shared/models/subscription_models.dart';

class PricingCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isMostPopular;
  final VoidCallback onSubscribe;
  final bool isLoading;

  const PricingCard({
    super.key,
    required this.plan,
    this.isMostPopular = false,
    required this.onSubscribe,
    this.isLoading = false,
  });

  Color _getTierColor() {
    switch (plan.tierLevel) {
      case 2: // Lite
        return const Color(0xFF10B981); // Green
      case 3: // Avid
        return const Color(0xFF8B5CF6); // Purple
      case 4: // Prime
        return const Color(0xFFF59E0B); // Amber
      default:
        return Colors.grey;
    }
  }

  IconData _getTierIcon() {
    switch (plan.tierName.toLowerCase()) {
      case 'lite':
        return Icons.menu_book;
      case 'avid':
        return Icons.bolt;
      case 'prime':
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }

  String _formatPrice() {
    final currencySymbols = {
      'USD': '\$',
      'NGN': '₦',
      'EUR': '€',
      'GBP': '£',
      'GHS': '₵',
      'ZAR': 'R',
      'KES': 'KSh',
    };

    final symbol = currencySymbols[plan.currency] ?? plan.currency;
    
    if (plan.currency == 'USD' || plan.currency == 'EUR' || plan.currency == 'GBP') {
      return '$symbol${plan.price.toStringAsFixed(2)}';
    } else {
      return '$symbol${plan.price.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMostPopular
              ? [
                  Colors.white,
                  tierColor.withOpacity(0.05),
                ]
              : [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: isMostPopular
            ? Border.all(color: tierColor.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isMostPopular
                ? tierColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top gradient bar for most popular
          if (isMostPopular)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tierColor, tierColor.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
            ),

          // Popular badge
          if (isMostPopular)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: tierColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Most Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Content
          Padding(
            padding: EdgeInsets.all(isMostPopular ? 32 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isMostPopular) const SizedBox(height: 24),

                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tierColor, tierColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getTierIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                // Tier name
                Text(
                  plan.tierName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  'Perfect for your reading style',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatPrice(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: tierColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '/month',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'Billed monthly',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 24),

                // Features list
                ...plan.benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: tierColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tierColor,
                      foregroundColor: Colors.white,
                      elevation: isMostPopular ? 8 : 2,
                      shadowColor: tierColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Subscribe Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

