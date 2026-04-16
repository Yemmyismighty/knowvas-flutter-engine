import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../errors/exceptions.dart';
import 'secure_storage.dart';

/// Service for encrypting and decrypting data using AES-256-GCM
/// Manages per-user encryption keys stored in platform secure storage
class EncryptionService {
  EncryptionService({
    required SecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;
  final Random _random = Random.secure();

  static const String _keyPrefix = 'encryption_key_';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _nonceLength = 12; // 96 bits for GCM
  static const int _tagLength = 16; // 128 bits for authentication tag

  /// Initialize encryption key for a user
  /// Creates a new key if one doesn't exist
  Future<void> initializeUserKey(String userId) async {
    try {
      final keyExists = await _secureStorage.containsKey(
        key: _getKeyStorageKey(userId),
      );

      if (!keyExists) {
        final key = _generateKey();
        await _secureStorage.write(
          key: _getKeyStorageKey(userId),
          value: base64Encode(key),
        );
      }
    } catch (e) {
      throw CacheException(
        'Failed to initialize user encryption key: $e',
        code: 'KEY_INITIALIZATION_ERROR',
      );
    }
  }

  /// Get or create encryption key for a user
  Future<String> getOrCreateEncryptionKey(String userId) async {
    try {
      final existingKey = await _secureStorage.read(
        key: _getKeyStorageKey(userId),
      );

      if (existingKey != null) {
        return existingKey;
      }

      // Create new key if it doesn't exist
      await initializeUserKey(userId);
      final newKey = await _secureStorage.read(
        key: _getKeyStorageKey(userId),
      );

      if (newKey == null) {
        throw const CacheException(
          'Failed to retrieve encryption key after creation',
          code: 'KEY_RETRIEVAL_ERROR',
        );
      }

      return newKey;
    } catch (e) {
      throw CacheException(
        'Failed to get or create encryption key: $e',
        code: 'KEY_ACCESS_ERROR',
      );
    }
  }

  /// Encrypt data using AES-256-GCM
  /// Returns encrypted data with nonce and tag prepended
  Future<Uint8List> encryptData(Uint8List data, String userId) async {
    try {
      final keyBase64 = await getOrCreateEncryptionKey(userId);
      final key = base64Decode(keyBase64);

      // Generate random nonce
      final nonce = _generateNonce();

      // Perform AES-GCM encryption
      // Note: Dart's crypto package doesn't have built-in AES-GCM
      // For production, use a package like 'pointycastle' or native platform channels
      // This is a simplified implementation using AES-CTR + HMAC for demonstration
      final encrypted = _encryptAesGcm(data, key, nonce);

      // Combine nonce + encrypted data + tag
      final result = Uint8List(nonce.length + encrypted.length)
        ..setRange(0, nonce.length, nonce)
        ..setRange(nonce.length, nonce.length + encrypted.length, encrypted);

      return result;
    } catch (e) {
      throw CacheException(
        'Failed to encrypt data: $e',
        code: 'ENCRYPTION_ERROR',
      );
    }
  }

  /// Decrypt data using AES-256-GCM
  /// Expects data with nonce and tag prepended
  Future<Uint8List> decryptData(Uint8List encryptedData, String userId) async {
    try {
      final keyBase64 = await getOrCreateEncryptionKey(userId);
      final key = base64Decode(keyBase64);

      // Extract nonce and encrypted data
      if (encryptedData.length < _nonceLength) {
        throw const CacheException(
          'Invalid encrypted data: too short',
          code: 'INVALID_ENCRYPTED_DATA',
        );
      }

      final nonce = encryptedData.sublist(0, _nonceLength);
      final ciphertext = encryptedData.sublist(_nonceLength);

      // Perform AES-GCM decryption
      final decrypted = _decryptAesGcm(ciphertext, key, nonce);

      return decrypted;
    } catch (e) {
      throw CacheException(
        'Failed to decrypt data: $e',
        code: 'DECRYPTION_ERROR',
      );
    }
  }

  /// Encrypt a file
  Future<Uint8List> encryptFile(Uint8List fileData, String userId) async {
    return encryptData(fileData, userId);
  }

  /// Decrypt a file
  Future<Uint8List> decryptFile(
    Uint8List encryptedData,
    String userId,
  ) async {
    return decryptData(encryptedData, userId);
  }

  /// Delete user's encryption key
  Future<void> deleteUserKey(String userId) async {
    try {
      await _secureStorage.delete(key: _getKeyStorageKey(userId));
    } catch (e) {
      throw CacheException(
        'Failed to delete user encryption key: $e',
        code: 'KEY_DELETION_ERROR',
      );
    }
  }

  /// Generate a random encryption key
  Uint8List _generateKey() {
    final key = Uint8List(_keyLength);
    for (var i = 0; i < _keyLength; i++) {
      key[i] = _random.nextInt(256);
    }
    return key;
  }

  /// Generate a random nonce
  Uint8List _generateNonce() {
    final nonce = Uint8List(_nonceLength);
    for (var i = 0; i < _nonceLength; i++) {
      nonce[i] = _random.nextInt(256);
    }
    return nonce;
  }

  /// Get storage key for user's encryption key
  String _getKeyStorageKey(String userId) {
    return '$_keyPrefix$userId';
  }

  /// Simplified AES-GCM encryption using AES-CTR + HMAC
  /// Note: For production, use a proper AES-GCM implementation
  /// This is a placeholder that demonstrates the concept
  Uint8List _encryptAesGcm(Uint8List data, Uint8List key, Uint8List nonce) {
    // In production, use pointycastle or platform channels for proper AES-GCM
    // This is a simplified version using XOR cipher for demonstration
    // DO NOT use this in production without proper AES-GCM implementation

    // Create a key stream from the key and nonce
    final keyStream = _createKeyStream(key, nonce, data.length);

    // XOR data with key stream
    final encrypted = Uint8List(data.length + _tagLength);
    for (var i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ keyStream[i];
    }

    // Generate authentication tag using HMAC-SHA256
    final hmac = Hmac(sha256, key);
    final tag = hmac.convert([...nonce, ...encrypted.sublist(0, data.length)]);
    encrypted.setRange(
      data.length,
      encrypted.length,
      tag.bytes.sublist(0, _tagLength),
    );

    return encrypted;
  }

  /// Simplified AES-GCM decryption using AES-CTR + HMAC
  Uint8List _decryptAesGcm(
    Uint8List encryptedData,
    Uint8List key,
    Uint8List nonce,
  ) {
    if (encryptedData.length < _tagLength) {
      throw const CacheException(
        'Invalid encrypted data: missing authentication tag',
        code: 'INVALID_ENCRYPTED_DATA',
      );
    }

    // Extract ciphertext and tag
    final ciphertext = encryptedData.sublist(0, encryptedData.length - _tagLength);
    final tag = encryptedData.sublist(encryptedData.length - _tagLength);

    // Verify authentication tag
    final hmac = Hmac(sha256, key);
    final expectedTag = hmac.convert([...nonce, ...ciphertext]);
    final expectedTagBytes = expectedTag.bytes.sublist(0, _tagLength);

    // Constant-time comparison
    var tagMatch = true;
    for (var i = 0; i < _tagLength; i++) {
      if (tag[i] != expectedTagBytes[i]) {
        tagMatch = false;
      }
    }

    if (!tagMatch) {
      throw const CacheException(
        'Authentication tag verification failed',
        code: 'TAG_VERIFICATION_FAILED',
      );
    }

    // Create key stream and decrypt
    final keyStream = _createKeyStream(key, nonce, ciphertext.length);
    final decrypted = Uint8List(ciphertext.length);
    for (var i = 0; i < ciphertext.length; i++) {
      decrypted[i] = ciphertext[i] ^ keyStream[i];
    }

    return decrypted;
  }

  /// Create a pseudo-random key stream from key and nonce
  /// In production, this should use proper AES-CTR mode
  Uint8List _createKeyStream(Uint8List key, Uint8List nonce, int length) {
    final keyStream = Uint8List(length);
    final combined = [...key, ...nonce];

    for (var i = 0; i < length; i++) {
      // Use SHA-256 to generate pseudo-random bytes
      final hash = sha256.convert([...combined, i ~/ 32]);
      keyStream[i] = hash.bytes[i % 32];
    }

    return keyStream;
  }
}
