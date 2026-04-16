import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _kDeviceIdKey = 'knowvas_device_id';
const _kDeviceNameKey = 'knowvas_device_name';

/// Provides a stable, hardware-backed device ID and a human-readable device name.
///
/// On Android we use [AndroidDeviceInfo.id] (a hardware-derived identifier).
/// On iOS we use [IosDeviceInfo.identifierForVendor].
/// As a fallback we generate a UUID and persist it in secure storage so it
/// survives app restarts but is unique per install.
class DeviceService {
  DeviceService._();

  static final DeviceService instance = DeviceService._();

  final _storage = const FlutterSecureStorage();
  final _plugin = DeviceInfoPlugin();

  String? _cachedId;
  String? _cachedName;

  /// Returns a stable unique device ID, generating and persisting one if needed.
  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        // androidInfo.id is a hardware-derived 64-bit identifier
        _cachedId = 'android-${info.id}';
      } else if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        // identifierForVendor is stable per app vendor per device
        _cachedId = 'ios-${info.identifierForVendor ?? await _getFallbackId()}';
      } else {
        _cachedId = await _getFallbackId();
      }
    } catch (e) {
      debugPrint('⚠️ DeviceService: could not read hardware ID, using fallback: $e');
      _cachedId = await _getFallbackId();
    }

    await _storage.write(key: _kDeviceIdKey, value: _cachedId);
    return _cachedId!;
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
        _cachedName = info.name; // e.g. "John's iPhone"
      } else {
        _cachedName = 'Unknown Device';
      }
    } catch (e) {
      _cachedName = 'Mobile Device';
    }

    await _storage.write(key: _kDeviceNameKey, value: _cachedName);
    return _cachedName!;
  }

  /// UUID-based fallback — persisted in secure storage so it's stable across launches.
  Future<String> _getFallbackId() async {
    final stored = await _storage.read(key: _kDeviceIdKey);
    if (stored != null) return stored;
    final id = 'mobile-${const Uuid().v4()}';
    await _storage.write(key: _kDeviceIdKey, value: id);
    return id;
  }
}
