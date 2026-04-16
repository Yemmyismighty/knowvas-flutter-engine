import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import 'cart_repository.dart';

/// Provider for CartRepository
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CartRepository(apiClient: apiClient);
});
