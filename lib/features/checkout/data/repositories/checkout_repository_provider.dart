import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/core/network/api_client_provider.dart';
import 'checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider));
});
