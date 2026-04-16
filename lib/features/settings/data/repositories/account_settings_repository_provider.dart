import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/core/services/storage_service.dart';
import 'package:knowvas/features/settings/data/repositories/account_settings_repository.dart';

final accountSettingsRepositoryProvider = Provider<AccountSettingsRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return AccountSettingsRepository(storageService);
});

