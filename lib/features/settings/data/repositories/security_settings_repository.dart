import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowvas/core/constants/api_constants.dart';
import 'package:knowvas/shared/models/security_settings_models.dart';
import 'package:knowvas/core/services/storage_service.dart';

class SecuritySettingsRepository {
  final StorageService _storageService;

  SecuritySettingsRepository(this._storageService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Change password
  Future<void> changePassword(PasswordChangeRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/change-password'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? data['error'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  /// Get devices
  Future<List<DeviceInfo>> getDevices() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/user/devices'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final devices = (data['data'] as List)
            .map((device) => DeviceInfo.fromJson(device))
            .toList();
        return devices;
      } else {
        throw Exception('Failed to load devices');
      }
    } catch (e) {
      throw Exception('Error fetching devices: $e');
    }
  }

  /// Sign out device
  Future<void> signOutDevice(int deviceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/devices/$deviceId/sign-out'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to sign out device');
      }
    } catch (e) {
      throw Exception('Error signing out device: $e');
    }
  }

  /// Sign out all devices
  Future<void> signOutAllDevices() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/devices/sign-out-all'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to sign out all devices');
      }
    } catch (e) {
      throw Exception('Error signing out all devices: $e');
    }
  }

  /// Get MFA status
  Future<MfaStatus> getMfaStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/user/mfa/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MfaStatus.fromJson(data['data']);
      } else {
        throw Exception('Failed to load MFA status');
      }
    } catch (e) {
      throw Exception('Error fetching MFA status: $e');
    }
  }

  /// Toggle MFA
  Future<void> toggleMfa(bool enable, {String? password}) async {
    try {
      final headers = await _getHeaders();
      final endpoint = enable ? 'enable' : 'disable';
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/mfa/$endpoint'),
        headers: headers,
        body: json.encode({'password': password}),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? data['error'] ?? 'Failed to toggle MFA');
      }
    } catch (e) {
      throw Exception('Error toggling MFA: $e');
    }
  }
}

