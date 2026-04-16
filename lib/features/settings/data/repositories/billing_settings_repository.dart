import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowvas/core/constants/api_constants.dart';
import 'package:knowvas/shared/models/billing_settings_models.dart';
import 'package:knowvas/core/services/storage_service.dart';

class BillingSettingsRepository {
  final StorageService _storageService;

  BillingSettingsRepository(this._storageService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get current subscription
  Future<CurrentSubscriptionInfo?> getCurrentSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/subscription/current'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['subscription'] != null) {
          return CurrentSubscriptionInfo.fromJson(data['subscription']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null; // No subscription
      } else {
        throw Exception('Failed to load subscription');
      }
    } catch (e) {
      throw Exception('Error fetching subscription: $e');
    }
  }

  /// Get subscription usage
  Future<SubscriptionUsage> getSubscriptionUsage() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/user/subscription-usage'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionUsage.fromJson(data['data']);
      } else {
        throw Exception('Failed to load subscription usage');
      }
    } catch (e) {
      throw Exception('Error fetching subscription usage: $e');
    }
  }

  /// Get subscription management link
  Future<String> getManageLink() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/subscription/manage-link'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['manage_link'];
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to get management link');
      }
    } catch (e) {
      throw Exception('Error getting management link: $e');
    }
  }
}

