import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/core/services/storage_service.dart';
import 'package:knowvas/features/settings/data/repositories/security_settings_repository.dart';

final securitySettingsRepositoryProvider = Provider<SecuritySettingsRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SecuritySettingsRepository(storageService);
});

