import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/security/encryption_service.dart';
import 'package:knowvas/core/security/secure_storage.dart';

void main() {
  late EncryptionService encryptionService;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    encryptionService = EncryptionService(
      secureStorage: mockSecureStorage,
    );
  });

  group('EncryptionService', () {
    const userId = 'test_user_123';

    test('initializeUserKey should create a new key', () async {
      // Act
      await encryptionService.initializeUserKey(userId);

      // Assert
      final key = await mockSecureStorage.read(key: 'encryption_key_$userId');
      expect(key, isNotNull);
      expect(key!.length, greaterThan(0));
    });

    test('initializeUserKey should not overwrite existing key', () async {
      // Arrange
      await encryptionService.initializeUserKey(userId);
      final firstKey = await mockSecureStorage.read(
        key: 'encryption_key_$userId',
      );

      // Act
      await encryptionService.initializeUserKey(userId);
      final secondKey = await mockSecureStorage.read(
        key: 'encryption_key_$userId',
      );

      // Assert
      expect(firstKey, equals(secondKey));
    });

    test('getOrCreateEncryptionKey should return existing key', () async {
      // Arrange
      await encryptionService.initializeUserKey(userId);
      final expectedKey = await mockSecureStorage.read(
        key: 'encryption_key_$userId',
      );

      // Act
      final key = await encryptionService.getOrCreateEncryptionKey(userId);

      // Assert
      expect(key, equals(expectedKey));
    });

    test('getOrCreateEncryptionKey should create key if not exists', () async {
      // Act
      final key = await encryptionService.getOrCreateEncryptionKey(userId);

      // Assert
      expect(key, isNotNull);
      expect(key.length, greaterThan(0));
    });

    test('encryptData and decryptData should work round-trip', () async {
      // Arrange
      final plaintext = Uint8List.fromList(
        utf8.encode('This is sensitive data that needs encryption'),
      );

      // Act
      final encrypted = await encryptionService.encryptData(plaintext, userId);
      final decrypted = await encryptionService.decryptData(encrypted, userId);

      // Assert
      expect(decrypted, equals(plaintext));
      expect(encrypted, isNot(equals(plaintext)));
    });

    test('encryptFile and decryptFile should work round-trip', () async {
      // Arrange
      final fileData = Uint8List.fromList(
        List.generate(1000, (index) => index % 256),
      );

      // Act
      final encrypted = await encryptionService.encryptFile(fileData, userId);
      final decrypted = await encryptionService.decryptFile(encrypted, userId);

      // Assert
      expect(decrypted, equals(fileData));
      expect(encrypted, isNot(equals(fileData)));
    });

    test('encrypted data should be different each time (random nonce)',
        () async {
      // Arrange
      final plaintext = Uint8List.fromList(utf8.encode('test data'));

      // Act
      final encrypted1 = await encryptionService.encryptData(plaintext, userId);
      final encrypted2 = await encryptionService.encryptData(plaintext, userId);

      // Assert
      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('deleteUserKey should remove encryption key', () async {
      // Arrange
      await encryptionService.initializeUserKey(userId);
      final keyExists = await mockSecureStorage.containsKey(
        key: 'encryption_key_$userId',
      );
      expect(keyExists, true);

      // Act
      await encryptionService.deleteUserKey(userId);

      // Assert
      final keyExistsAfter = await mockSecureStorage.containsKey(
        key: 'encryption_key_$userId',
      );
      expect(keyExistsAfter, false);
    });

    test('decryptData should fail with tampered data', () async {
      // Arrange
      final plaintext = Uint8List.fromList(utf8.encode('test data'));
      final encrypted = await encryptionService.encryptData(plaintext, userId);

      // Tamper with the encrypted data
      encrypted[encrypted.length - 1] ^= 0xFF;

      // Act & Assert
      expect(
        () => encryptionService.decryptData(encrypted, userId),
        throwsA(isA<Exception>()),
      );
    });

    test('different users should have different keys', () async {
      // Arrange
      const userId1 = 'user_1';
      const userId2 = 'user_2';

      // Act
      final key1 = await encryptionService.getOrCreateEncryptionKey(userId1);
      final key2 = await encryptionService.getOrCreateEncryptionKey(userId2);

      // Assert
      expect(key1, isNot(equals(key2)));
    });

    test('encrypted data with different user keys should not decrypt', () async {
      // Arrange
      const userId1 = 'user_1';
      const userId2 = 'user_2';
      final plaintext = Uint8List.fromList(utf8.encode('test data'));

      // Act
      final encrypted = await encryptionService.encryptData(plaintext, userId1);

      // Assert
      expect(
        () => encryptionService.decryptData(encrypted, userId2),
        throwsA(isA<Exception>()),
      );
    });
  });
}

/// Mock implementation of SecureStorage for testing
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_storage);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
