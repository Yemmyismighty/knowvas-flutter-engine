import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client_provider.dart';
import 'library_repository.dart';

/// Provider for library repository
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LibraryRepository(apiClient: apiClient);
});
