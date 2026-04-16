import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/core/services/storage_service.dart';
import 'package:knowvas/features/author/data/repositories/author_repository.dart';

final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return AuthorRepository(storageService);
});

