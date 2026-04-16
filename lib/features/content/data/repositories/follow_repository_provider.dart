import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client_provider.dart';
import 'follow_repository.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FollowRepository(apiClient: apiClient);
});
