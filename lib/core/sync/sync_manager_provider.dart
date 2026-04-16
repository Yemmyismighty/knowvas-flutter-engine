import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../network/api_client_provider.dart';
import '../network/connectivity_provider.dart';
import 'sync_manager.dart';

/// Provider for SyncManager
final syncManagerProvider = Provider<SyncManager>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final apiClient = ref.watch(apiClientProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final logger = ref.watch(loggerProvider);

  final syncManager = SyncManager(
    databaseHelper: databaseHelper,
    apiClient: apiClient,
    networkInfo: networkInfo,
    logger: logger,
  );

  // Dispose when provider is disposed
  ref.onDispose(() {
    syncManager.dispose();
  });

  return syncManager;
});

/// Provider for sync status
final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  return SyncStatus.idle;
});

/// Provider for last sync time
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) {
  return null;
});

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}
