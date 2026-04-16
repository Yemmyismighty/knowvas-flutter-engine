import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'download_notification_service.dart';

part 'download_notification_service_provider.g.dart';

/// Provider for DownloadNotificationService
@riverpod
DownloadNotificationService downloadNotificationService(
  DownloadNotificationServiceRef ref,
) {
  final service = DownloadNotificationService();
  
  // Initialize on first access
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
}
