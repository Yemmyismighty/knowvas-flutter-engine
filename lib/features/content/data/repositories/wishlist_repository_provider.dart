import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client_provider.dart';
import 'wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WishlistRepository(apiClient: apiClient);
});
