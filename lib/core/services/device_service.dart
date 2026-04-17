import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _kDeviceIdKey = 'knowvas_device_id';
const _kDeviceNameKey = 'knowvas_device_name';

/// Provides a stable unique device ID and a human-readable device name.
///
/// The device ID is a UUID persisted in secure storage — unique per app install,
/// stable across restarts, and not affected by OS build fingerprints being shared
/// across devices. It is prefixed with the platform for readability.
class DeviceService {
  DeviceService._();

  static final DeviceService instance = DeviceService._();

  final _storage = const FlutterSecureStorage();
  final _plugin = DeviceInfoPlugin();

  String? _cachedId;
  String? _cachedName;

  /// Returns a stable unique device ID.
  /// Generated once per install and persisted in secure storage.
  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    // Check if we already have a persisted ID for this install
    try {
      final stored = await _storage.read(key: _kDeviceIdKey);
      if (stored != null && stored.isNotEmpty) {
        // Migrate away from the old build-fingerprint format (android-UP1A.xxx)
        // which is NOT unique per device — it's the same on every phone running
        // that Android build. Detect it by checking if it looks like a build ID
        // rather than a UUID (UUIDs contain hyphens in the pattern xxxxxxxx-xxxx-...).
        final isOldFormat = _isOldBuildFingerprintFormat(stored);
        if (!isOldFormat) {
          _cachedId = stored;
          return _cachedId!;
        }
        // Old format — fall through to generate a new UUID-based ID
        debugPrint('⚠️ DeviceService: migrating old device ID format: $stored');
      }
    } catch (_) {}

    // Generate a new UUID-based ID, prefixed with platform
    try {
      final prefix = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'mobile';
      _cachedId = '$prefix-${const Uuid().v4()}';
    } catch (e) {
      _cachedId = 'mobile-${const Uuid().v4()}';
    }

    try {
      await _storage.write(key: _kDeviceIdKey, value: _cachedId);
    } catch (_) {}

    debugPrint('✅ DeviceService: device ID: $_cachedId');
    return _cachedId!;
  }

  /// Detects the old build-fingerprint format like "android-UP1A.231005.007"
  /// vs the new UUID format like "android-550e8400-e29b-41d4-a716-446655440000".
  /// UUIDs always have exactly 4 hyphens in the UUID portion; build IDs have dots.
  bool _isOldBuildFingerprintFormat(String id) {
    // New format: "android-{uuid}" where uuid has pattern 8-4-4-4-12 hex chars
    final uuidPattern = RegExp(
      r'^(android|ios|mobile)-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return !uuidPattern.hasMatch(id);
  }

  /// Returns a human-readable device name, e.g. "Samsung Galaxy S23" or "iPhone 15 Pro".
  Future<String> getDeviceName() async {
    if (_cachedName != null) return _cachedName!;

    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        _cachedName = '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        _cachedName = info.name;
      } else {
        _cachedName = 'Unknown Device';
      }
    } catch (e) {
      _cachedName = 'Mobile Device';
    }

    try {
      await _storage.write(key: _kDeviceNameKey, value: _cachedName);
    } catch (_) {}

    return _cachedName!;
  }
}
