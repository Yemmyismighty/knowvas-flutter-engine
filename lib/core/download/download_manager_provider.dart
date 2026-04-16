import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import '../security/encryption_service_provider.dart';
import 'download_manager.dart';

part 'download_manager_provider.g.dart';

/// Provider for DownloadManager
@riverpod
DownloadManager downloadManager(DownloadManagerRef ref) {
  final dio = Dio();
  final encryptionService = ref.watch(encryptionServiceProvider);
  final database = KnowvasDatabase();
  
  final manager = DownloadManager(
    dio: dio,
    encryptionService: encryptionService,
    database: database,
  );
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
}
