import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/core/services/storage_service.dart';
import 'package:knowvas/features/settings/data/repositories/billing_settings_repository.dart';

final billingSettingsRepositoryProvider = Provider<BillingSettingsRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return BillingSettingsRepository(storageService);
});

