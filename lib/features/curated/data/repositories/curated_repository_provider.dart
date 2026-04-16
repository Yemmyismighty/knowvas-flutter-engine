import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/core/network/api_client_provider.dart';
import 'curated_repository.dart';

final curatedRepositoryProvider = Provider<CuratedRepository>((ref) {
  return CuratedRepository(ref.watch(apiClientProvider));
});
