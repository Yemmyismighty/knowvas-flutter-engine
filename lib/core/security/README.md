# Security Module

This module provides secure storage and encryption services for the Knowvas Flutter client.

## Components

### SecureStorage (`secure_storage.dart`)

A wrapper around `flutter_secure_storage` that provides secure key-value storage using platform-specific secure storage mechanisms:

- **Android**: Uses Android Keystore with encrypted shared preferences
- **iOS**: Uses iOS Keychain with `first_unlock` accessibility

**Key Features:**
- Write/read/delete operations for secure key-value pairs
- Automatic encryption at rest using platform secure storage
- Error handling with custom exceptions

**Usage:**
```dart
final secureStorage = SecureStorage();

// Write
await secureStorage.write(key: 'token', value: 'jwt_token_here');

// Read
final token = await secureStorage.read(key: 'token');

// Delete
await secureStorage.delete(key: 'token');

// Delete all
await secureStorage.deleteAll();
```

### EncryptionService (`encryption_service.dart`)

Provides AES-256-GCM encryption for data and files with per-user key management.

**Key Features:**
- Per-user encryption keys stored in platform secure storage
- AES-256-GCM encryption (simplified implementation)
- Automatic key generation and management
- File encryption/decryption support

**Important Note:**
The current implementation uses a simplified encryption approach (AES-CTR + HMAC) for demonstration purposes. For production use, this should be replaced with a proper AES-GCM implementation using one of the following:

1. **pointycastle** package - Pure Dart cryptography library
2. **Platform channels** - Native AES-GCM implementation (recommended for best performance)
3. **cryptography** package - Modern Dart cryptography library

**Usage:**
```dart
final encryptionService = EncryptionService(
  secureStorage: secureStorage,
);

// Initialize user key
await encryptionService.initializeUserKey('user_123');

// Encrypt data
final plaintext = Uint8List.fromList(utf8.encode('sensitive data'));
final encrypted = await encryptionService.encryptData(plaintext, 'user_123');

// Decrypt data
final decrypted = await encryptionService.decryptData(encrypted, 'user_123');

// Encrypt file
final fileData = await File('path/to/file').readAsBytes();
final encryptedFile = await encryptionService.encryptFile(fileData, 'user_123');

// Decrypt file
final decryptedFile = await encryptionService.decryptFile(encryptedFile, 'user_123');

// Delete user key
await encryptionService.deleteUserKey('user_123');
```

## Security Considerations

### Key Storage
- Encryption keys are stored in platform secure storage (Android Keystore/iOS Keychain)
- Keys are never exposed in logs or error messages
- Each user has a unique encryption key

### Encryption Algorithm
- **Algorithm**: AES-256-GCM (simplified implementation)
- **Key Size**: 256 bits (32 bytes)
- **Nonce Size**: 96 bits (12 bytes)
- **Tag Size**: 128 bits (16 bytes)

### Data Format
Encrypted data format:
```
[nonce (12 bytes)] + [ciphertext (variable)] + [authentication tag (16 bytes)]
```

### Best Practices
1. Always initialize user keys before encrypting/decrypting
2. Delete user keys when user logs out or deletes account
3. Never store encryption keys in plain text
4. Use secure random number generation for keys and nonces
5. Verify authentication tags before decrypting

## Requirements Satisfied

This implementation satisfies the following requirements:

- **15.3**: JWT tokens stored using platform secure storage (Android Keystore, iOS Keychain)
- **15.4**: Encryption keys generated using platform keystore/keychain for secure key storage
- **15.5**: Downloaded files encrypted at rest using per-user encryption keys
- **8.6**: File encryption at rest using per-user encryption key stored in platform keystore/keychain
- **8.7**: Decryption on-the-fly when opening downloaded content

## Testing

Unit tests for this module should cover:
- Key generation and storage
- Encryption/decryption round-trip
- Error handling for invalid data
- Key deletion
- Multiple user key management

## Future Improvements

1. **Replace with proper AES-GCM**: Use `pointycastle` or platform channels for production-grade AES-GCM
2. **Key rotation**: Implement periodic key rotation for enhanced security
3. **Biometric authentication**: Add biometric unlock for accessing encryption keys
4. **Hardware security**: Leverage hardware-backed keystores where available
5. **Key derivation**: Use PBKDF2 or Argon2 for deriving keys from user passwords if needed
