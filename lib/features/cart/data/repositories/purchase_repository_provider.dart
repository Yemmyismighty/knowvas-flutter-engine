import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'purchase_repository.dart';

part 'purchase_repository_provider.g.dart';

/// Provider for PurchaseRepository
@riverpod
PurchaseRepository purchaseRepository(PurchaseRepositoryRef ref) {
  return PurchaseRepository(
    apiClient: ref.watch(apiClientProvider),
  );
}
