import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/content_detail.dart';
import '../../../discover/data/repositories/content_repository.dart';
import '../../../discover/data/repositories/content_repository_provider.dart';

/// Provider for fetching content details by ID
final contentDetailsProvider = FutureProvider.family<ContentDetail, String>((ref, contentId) async {
  final repository = ref.watch(contentRepositoryProvider);
  
  try {
    final id = int.parse(contentId);
    return await repository.getContentDetail(id);
  } catch (e) {
    throw Exception('Failed to load content details: $e');
  }
});
