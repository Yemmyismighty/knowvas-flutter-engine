import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Service for encrypted file storage
/// Stores downloaded content in app's private directory with encryption
class EncryptedStorageService {
  static final EncryptedStorageService _instance = EncryptedStorageService._internal();
  factory EncryptedStorageService() => _instance;
  EncryptedStorageService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  /// Get encryption key for a content item
  /// Creates new key if doesn't exist
  Future<String> _getEncryptionKey(String contentId) async {
    final keyName = 'content_key_$contentId';
    String? key = await _secureStorage.read(key: keyName);
    
    if (key == null) {
      // Generate new 256-bit key
      final keyBytes = encrypt.Key.fromSecureRandom(32);
      key = keyBytes.base64;
      await _secureStorage.write(key: keyName, value: key);
      debugPrint('🔑 Generated new encryption key for content: $contentId');
    }
    
    return key;
  }
  
  /// Get storage directory for content files
  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final contentDir = Directory('${appDir.path}/encrypted_content');
    
    if (!await contentDir.exists()) {
      await contentDir.create(recursive: true);
    }
    
    return contentDir;
  }
  
  /// Encrypt and save file
  Future<String> saveEncryptedFile({
    required String contentId,
    required Uint8List data,
    required String fileExtension,
  }) async {
    try {
      // Get encryption key
      final keyString = await _getEncryptionKey(contentId);
      final key = encrypt.Key.fromBase64(keyString);
      
      // Generate IV
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // Encrypt data
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encryptBytes(data, iv: iv);
      
      // Save encrypted file
      final dir = await _getStorageDirectory();
      final fileName = '$contentId.$fileExtension.enc';
      final file = File('${dir.path}/$fileName');
      
      // Write IV + encrypted data
      final fileData = Uint8List.fromList([
        ...iv.bytes,
        ...encrypted.bytes,
      ]);
      
      await file.writeAsBytes(fileData);
      
      debugPrint('✅ Encrypted file saved: $fileName (${fileData.length} bytes)');
      return file.path;
    } catch (e) {
      debugPrint('❌ Failed to save encrypted file: $e');
      rethrow;
    }
  }
  
  /// Load and decrypt file
  Future<Uint8List?> loadEncryptedFile({
    required String contentId,
    required String fileExtension,
  }) async {
    try {
      // Get file path
      final dir = await _getStorageDirectory();
      final fileName = '$contentId.$fileExtension.enc';
      final file = File('${dir.path}/$fileName');
      
      if (!await file.exists()) {
        debugPrint('⚠️ Encrypted file not found: $fileName');
        return null;
      }
      
      // Read file
      final fileData = await file.readAsBytes();
      
      // Extract IV and encrypted data
      final iv = encrypt.IV(Uint8List.fromList(fileData.sublist(0, 16)));
      final encryptedData = fileData.sublist(16);
      
      // Get encryption key
      final keyString = await _getEncryptionKey(contentId);
      final key = encrypt.Key.fromBase64(keyString);
      
      // Decrypt
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedData),
        iv: iv,
      );
      
      debugPrint('✅ Decrypted file loaded: $fileName (${decrypted.length} bytes)');
      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('❌ Failed to load encrypted file: $e');
      return null;
    }
  }
  
  /// Check if file exists
  Future<bool> fileExists({
    required String contentId,
    required String fileExtension,
  }) async {
    final dir = await _getStorageDirectory();
    final fileName = '$contentId.$fileExtension.enc';
    final file = File('${dir.path}/$fileName');
    return await file.exists();
  }
  
  /// Delete encrypted file
  Future<void> deleteEncryptedFile({
    required String contentId,
    required String fileExtension,
  }) async {
    try {
      final dir = await _getStorageDirectory();
      final fileName = '$contentId.$fileExtension.enc';
      final file = File('${dir.path}/$fileName');
      
      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ Deleted encrypted file: $fileName');
      }
      
      // Also delete encryption key
      final keyName = 'content_key_$contentId';
      await _secureStorage.delete(key: keyName);
    } catch (e) {
      debugPrint('❌ Failed to delete encrypted file: $e');
    }
  }
  
  /// Get file size
  Future<int?> getFileSize({
    required String contentId,
    required String fileExtension,
  }) async {
    try {
      final dir = await _getStorageDirectory();
      final fileName = '$contentId.$fileExtension.enc';
      final file = File('${dir.path}/$fileName');
      
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get file size: $e');
      return null;
    }
  }
  
  /// Clear all encrypted files
  Future<void> clearAll() async {
    try {
      final dir = await _getStorageDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        debugPrint('✅ Cleared all encrypted files');
      }
      
      // Clear all encryption keys
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('❌ Failed to clear encrypted files: $e');
    }
  }

  /// Get temporary decrypted file path for readers that need file paths
  /// (like Iridium which can't read from memory)
  Future<String> getDecryptedTempPath({
    required String contentId,
    required String fileExtension,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/reader_temp/$contentId.$fileExtension';
    return tempPath;
  }

  /// Save decrypted data to temporary location
  /// Used for readers that need file paths instead of in-memory data
  Future<void> saveDecryptedTemp({
    required String contentId,
    required Uint8List data,
    required String fileExtension,
  }) async {
    try {
      final tempPath = await getDecryptedTempPath(
        contentId: contentId,
        fileExtension: fileExtension,
      );
      
      final file = File(tempPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data);
      
      debugPrint('💾 Saved decrypted temp file: $tempPath');
    } catch (e) {
      debugPrint('❌ Error saving decrypted temp: $e');
      rethrow;
    }
  }

  /// Delete temporary decrypted file
  Future<void> deleteDecryptedTemp({
    required String contentId,
    required String fileExtension,
  }) async {
    try {
      final tempPath = await getDecryptedTempPath(
        contentId: contentId,
        fileExtension: fileExtension,
      );
      
      final file = File(tempPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Deleted decrypted temp file');
      }
    } catch (e) {
      debugPrint('❌ Error deleting decrypted temp: $e');
    }
  }

  /// Clear all temporary decrypted files
  Future<void> clearAllDecryptedTemp() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final readerTempDir = Directory('${tempDir.path}/reader_temp');
      
      if (await readerTempDir.exists()) {
        await readerTempDir.delete(recursive: true);
        debugPrint('🗑️ Cleared all decrypted temp files');
      }
    } catch (e) {
      debugPrint('❌ Error clearing decrypted temp files: $e');
    }
  }
}