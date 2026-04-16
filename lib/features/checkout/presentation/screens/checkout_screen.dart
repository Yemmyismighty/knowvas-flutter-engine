import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:knowvas/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:knowvas/features/checkout/presentation/widgets/checkout_item_card.dart';
import 'package:knowvas/features/checkout/presentation/widgets/checkout_summary_card.dart';
import 'package:knowvas/features/auth/presentation/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch checkout data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        context.go('/auth/signin');
        return;
      }
      ref.read(checkoutProvider.notifier).fetchCheckoutData();
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

  Future<void> _handleCheckout() async {
    try {
      final response = await ref.read(checkoutProvider.notifier).initiatePayment();

      // Open payment URL in browser
      final uri = Uri.parse(response.authorizationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete payment in your browser'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Could not launch payment URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Redirect if not authenticated
    if (!authState.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a1a), const Color(0xFF0a0a0a)]
                : [const Color(0xFFF9FAFB), Colors.white],
          ),
        ),
        child: SafeArea(
          child: checkoutState.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading checkout...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : checkoutState.checkoutData == null ||
                      checkoutState.checkoutData!.itemCount == 0
                  ? _buildEmptyCart(context)
                  : _buildCheckoutContent(context, checkoutState),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Cart is Empty',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add items to your cart to proceed with checkout',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/discover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Browse Content',
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
      ),
    );
  }

  Widget _buildCheckoutContent(BuildContext context, CheckoutState checkoutState) {
    final checkoutData = checkoutState.checkoutData!;
    final currencySymbol = _getCurrencySymbol(checkoutData.currency);

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          floating: true,
        ),

        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review your items and complete your purchase',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error Alert
        if (checkoutState.error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
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
                        checkoutState.error!,
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;

                if (isWide) {
                  // Desktop layout: side by side
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Items (2/3)
                      Expanded(
                        flex: 2,
                        child: _buildItemsList(checkoutData, currencySymbol),
                      ),
                      const SizedBox(width: 24),
                      // Summary (1/3)
                      Expanded(
                        flex: 1,
                        child: CheckoutSummaryCard(
                          checkoutData: checkoutData,
                          currencySymbol: currencySymbol,
                          isProcessing: checkoutState.isProcessing,
                          onCheckout: _handleCheckout,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile layout: stacked
                  return Column(
                    children: [
                      _buildItemsList(checkoutData, currencySymbol),
                      const SizedBox(height: 24),
                      CheckoutSummaryCard(
                        checkoutData: checkoutData,
                        currencySymbol: currencySymbol,
                        isProcessing: checkoutState.isProcessing,
                        onCheckout: _handleCheckout,
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),

        // Info Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem('Your payment is secure and encrypted'),
                  const SizedBox(height: 12),
                  _buildInfoItem('You\'ll receive instant access to your purchases'),
                  const SizedBox(height: 12),
                  _buildInfoItem('A confirmation email will be sent to your account'),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildItemsList(checkoutData, String currencySymbol) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Text(
              'Order Items (${checkoutData.items.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Items
          ...checkoutData.items.map((item) => CheckoutItemCard(
                item: item,
                currencySymbol: currencySymbol,
              )),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          size: 16,
          color: Color(0xFF8B5CF6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}

