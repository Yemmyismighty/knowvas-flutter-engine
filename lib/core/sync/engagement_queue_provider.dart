import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../network/api_client_provider.dart';
import 'engagement_queue_service.dart';

/// Provider for EngagementQueueService
final engagementQueueServiceProvider = Provider<EngagementQueueService>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final logger = ref.watch(loggerProvider);

  return EngagementQueueService(
    databaseHelper: databaseHelper,
    logger: logger,
  );
});
