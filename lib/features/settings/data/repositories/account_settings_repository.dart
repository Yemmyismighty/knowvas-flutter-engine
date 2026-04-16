import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowvas/core/constants/api_constants.dart';
import 'package:knowvas/shared/models/account_settings_models.dart';
import 'package:knowvas/core/services/storage_service.dart';

class AccountSettingsRepository {
  final StorageService _storageService;

  AccountSettingsRepository(this._storageService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get account settings
  Future<AccountSettings> getAccountSettings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/user/account-settings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AccountSettings.fromJson(data['data']);
      } else {
        throw Exception('Failed to load account settings');
      }
    } catch (e) {
      throw Exception('Error fetching account settings: $e');
    }
  }

  /// Update account settings
  Future<AccountSettings> updateAccountSettings(AccountSettings settings) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/account-settings'),
        headers: headers,
        body: json.encode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AccountSettings.fromJson(data['data']);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to update account settings');
      }
    } catch (e) {
      throw Exception('Error updating account settings: $e');
    }
  }
}

