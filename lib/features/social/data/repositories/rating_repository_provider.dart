import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/network/network_info.dart';
import 'rating_repository.dart';

part 'rating_repository_provider.g.dart';

/// Provider for RatingRepository
@riverpod
RatingRepository ratingRepository(RatingRepositoryRef ref) {
  return RatingRepository(
    apiClient: ref.watch(apiClientProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
}
