import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _kDeviceIdKey = 'knowvas_device_id';
const _kDeviceNameKey = 'knowvas_device_name';

/// Provides a stable unique device ID and a human-readable device name.
///
/// The device ID is a UUID persisted in BOTH secure storage AND SharedPreferences.
/// Using two stores makes it resilient to debug hot-restarts (which can clear
/// the in-memory cache) and to occasional secure storage read failures.
/// The ID is generated once per install and never changes.
class DeviceService {
  DeviceService._();

  static final DeviceService instance = DeviceService._();

  final _secure = const FlutterSecureStorage();
  final _plugin = DeviceInfoPlugin();

  String? _cachedId;
  String? _cachedName;

  /// Returns a stable unique device ID.
  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    // 1. Try secure storage first
    try {
      final stored = await _secure.read(key: _kDeviceIdKey);
      if (stored != null && stored.isNotEmpty && !_isOldFormat(stored)) {
        _cachedId = stored;
        // Back-fill SharedPreferences in case it's missing
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kDeviceIdKey, stored);
        return _cachedId!;
      }
    } catch (_) {}

    // 2. Fall back to SharedPreferences (survives hot restarts in debug)
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kDeviceIdKey);
      if (stored != null && stored.isNotEmpty && !_isOldFormat(stored)) {
        _cachedId = stored;
        // Back-fill secure storage
        try {
          await _secure.write(key: _kDeviceIdKey, value: stored);
        } catch (_) {}
        return _cachedId!;
      }
    } catch (_) {}

    // 3. Generate a new UUID — first install or migration
    try {
      final prefix = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'mobile';
      _cachedId = '$prefix-${const Uuid().v4()}';
    } catch (_) {
      _cachedId = 'mobile-${const Uuid().v4()}';
    }

    // Persist to both stores
    try {
      await _secure.write(key: _kDeviceIdKey, value: _cachedId);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDeviceIdKey, _cachedId!);
    } catch (_) {}

    debugPrint('✅ DeviceService: device ID: $_cachedId');
    return _cachedId!;
  }

  /// Returns a human-readable device name.
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
    } catch (_) {
      _cachedName = 'Mobile Device';
    }

    return _cachedName!;
  }

  /// Detects the old build-fingerprint format (android-UP1A.231005.007)
  /// vs the new UUID format (android-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).
  bool _isOldFormat(String id) {
    final uuidPattern = RegExp(
      r'^(android|ios|mobile)-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return !uuidPattern.hasMatch(id);
  }
}
