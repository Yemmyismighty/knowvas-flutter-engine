import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:knowvas/features/settings/presentation/providers/billing_settings_provider.dart';

class BillingSettingsTab extends ConsumerStatefulWidget {
  const BillingSettingsTab({super.key});

  @override
  ConsumerState<BillingSettingsTab> createState() => _BillingSettingsTabState();
}

class _BillingSettingsTabState extends ConsumerState<BillingSettingsTab> {
  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingSettingsProvider.notifier).loadSubscription();
      ref.read(billingSettingsProvider.notifier).loadUsage();
    });
  }

  String _getCurrencySymbol(String currency) {
    const symbols = {
      'USD': '\$',
      'NGN': '₦',
      'EUR': '€',
      'GBP': '£',
      'GHS': '₵',
      'ZAR': 'R',
      'KES': 'KSh',
    };
    return symbols[currency] ?? currency;
  }

  Color _getTierColor(int tierLevel) {
    switch (tierLevel) {
      case 2:
        return const Color(0xFF10B981); // Green - Lite
      case 3:
        return const Color(0xFF8B5CF6); // Purple - Avid
      case 4:
        return const Color(0xFFF59E0B); // Amber - Prime
      default:
        return Colors.grey;
    }
  }

  IconData _getTierIcon(String tierName) {
    switch (tierName.toLowerCase()) {
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

  Future<void> _handleManageSubscription() async {
    try {
      final manageLink = await ref.read(billingSettingsProvider.notifier).getManageLink();
      final uri = Uri.parse(manageLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open management link', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to get management link', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingSettingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Subscription Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Current Subscription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (billingState.isLoadingSubscription)
                  const Center(child: CircularProgressIndicator())
                else if (billingState.subscription == null)
                  _buildNoSubscription()
                else
                  _buildSubscriptionInfo(billingState.subscription!),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Usage Statistics Card
          if (billingState.subscription != null && !billingState.subscription!.isFreebie)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Usage Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (billingState.isLoadingUsage)
                    const Center(child: CircularProgressIndicator())
                  else if (billingState.usage != null)
                    _buildUsageStats(billingState.usage!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoSubscription() {
    return Column(
      children: [
        Icon(Icons.credit_card_off, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'No Active Subscription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upgrade to unlock premium features',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/pricing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Plans'),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfo(subscription) {
    final tierColor = _getTierColor(subscription.tierLevel);
    final tierIcon = _getTierIcon(subscription.tierName);
    final currencySymbol = _getCurrencySymbol(subscription.currency);

    return Column(
      children: [
        // Tier Badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tierColor, tierColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(tierIcon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${subscription.tierName} Plan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (subscription.price != null)
                      Text(
                        '$currencySymbol${subscription.price!.toStringAsFixed(2)}/month',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subscription.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Benefits
        if (subscription.benefits.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Benefits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...subscription.benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: tierColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Action Buttons
        Row(
          children: [
            if (!subscription.isFreebie) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleManageSubscription,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Manage'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/pricing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tierColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(subscription.isFreebie ? 'Upgrade Plan' : 'Change Plan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsageStats(usage) {
    return Column(
      children: [
        _buildUsageItem(
          'Books Read This Month',
          usage.booksReadThisMonth.toString(),
          usage.getBookLimitDisplay(),
          usage.getBooksProgress(),
          Icons.menu_book,
          const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 16),
        _buildUsageItem(
          'Downloads',
          usage.downloadsThisMonth.toString(),
          usage.getDownloadsLimitDisplay(),
          usage.getDownloadsProgress(),
          Icons.download,
          const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),
        _buildUsageItem(
          'Storage Used',
          '${usage.storageUsedGB.toStringAsFixed(1)} GB',
          usage.getStorageLimitDisplay(),
          usage.getStorageProgress(),
          Icons.storage,
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        _buildUsageItem(
          'Connected Devices',
          usage.devicesConnected.toString(),
          '${usage.deviceLimit} devices',
          usage.devicesConnected / usage.deviceLimit,
          Icons.devices,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildUsageItem(
    String label,
    String value,
    String limit,
    double? progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '$value / $limit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

