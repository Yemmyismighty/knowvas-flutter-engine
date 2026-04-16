import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'encryption_service.dart';
import 'secure_storage.dart';

part 'encryption_service_provider.g.dart';

/// Provider for SecureStorage
@riverpod
SecureStorage secureStorage(SecureStorageRef ref) {
  return SecureStorage();
}

/// Provider for EncryptionService
@riverpod
EncryptionService encryptionService(EncryptionServiceRef ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return EncryptionService(secureStorage: secureStorage);
}
