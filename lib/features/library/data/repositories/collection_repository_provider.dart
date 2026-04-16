import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import 'collection_repository.dart';

part 'collection_repository_provider.g.dart';

/// Provider for CollectionRepository
@riverpod
CollectionRepository collectionRepository(CollectionRepositoryRef ref) {
  final apiClient = ref.watch(apiClientProvider);
  
  return CollectionRepository(
    apiClient: apiClient,
  );
}
