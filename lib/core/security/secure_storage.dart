import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/exceptions.dart';

/// Wrapper around FlutterSecureStorage for secure key-value storage
/// Uses platform-specific secure storage (Android Keystore, iOS Keychain)
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  /// Write a value to secure storage
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw CacheException(
        'Failed to write to secure storage: $e',
        code: 'SECURE_STORAGE_WRITE_ERROR',
      );
    }
  }

  /// Read a value from secure storage
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw CacheException(
        'Failed to read from secure storage: $e',
        code: 'SECURE_STORAGE_READ_ERROR',
      );
    }
  }

  /// Delete a value from secure storage
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw CacheException(
        'Failed to delete from secure storage: $e',
        code: 'SECURE_STORAGE_DELETE_ERROR',
      );
    }
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw CacheException(
        'Failed to delete all from secure storage: $e',
        code: 'SECURE_STORAGE_DELETE_ALL_ERROR',
      );
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw CacheException(
        'Failed to check key in secure storage: $e',
        code: 'SECURE_STORAGE_CONTAINS_ERROR',
      );
    }
  }

  /// Read all keys from secure storage
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw CacheException(
        'Failed to read all from secure storage: $e',
        code: 'SECURE_STORAGE_READ_ALL_ERROR',
      );
    }
  }
}
