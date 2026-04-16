import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/security/secure_storage.dart';

void main() {
  late SecureStorage secureStorage;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorage(storage: mockStorage);
  });

  group('SecureStorage', () {
    test('write should store value successfully', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';

      // Act
      await secureStorage.write(key: key, value: value);

      // Assert
      expect(mockStorage.storage[key], value);
    });

    test('read should retrieve stored value', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';
      mockStorage.storage[key] = value;

      // Act
      final result = await secureStorage.read(key: key);

      // Assert
      expect(result, value);
    });

    test('read should return null for non-existent key', () async {
      // Arrange
      const key = 'non_existent_key';

      // Act
      final result = await secureStorage.read(key: key);

      // Assert
      expect(result, null);
    });

    test('delete should remove value', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';
      mockStorage.storage[key] = value;

      // Act
      await secureStorage.delete(key: key);

      // Assert
      expect(mockStorage.storage.containsKey(key), false);
    });

    test('deleteAll should remove all values', () async {
      // Arrange
      mockStorage.storage['key1'] = 'value1';
      mockStorage.storage['key2'] = 'value2';

      // Act
      await secureStorage.deleteAll();

      // Assert
      expect(mockStorage.storage.isEmpty, true);
    });

    test('containsKey should return true for existing key', () async {
      // Arrange
      const key = 'test_key';
      mockStorage.storage[key] = 'value';

      // Act
      final result = await secureStorage.containsKey(key: key);

      // Assert
      expect(result, true);
    });

    test('containsKey should return false for non-existent key', () async {
      // Arrange
      const key = 'non_existent_key';

      // Act
      final result = await secureStorage.containsKey(key: key);

      // Assert
      expect(result, false);
    });

    test('readAll should return all stored values', () async {
      // Arrange
      mockStorage.storage['key1'] = 'value1';
      mockStorage.storage['key2'] = 'value2';

      // Act
      final result = await secureStorage.readAll();

      // Assert
      expect(result, {'key1': 'value1', 'key2': 'value2'});
    });
  });
}

/// Mock implementation of FlutterSecureStorage for testing
class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(storage);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
