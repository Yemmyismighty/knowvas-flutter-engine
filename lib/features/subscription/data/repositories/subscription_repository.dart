import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/core/errors/exceptions.dart';
import 'package:knowvas/core/errors/failures.dart';
import 'package:knowvas/shared/models/subscription_models.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SubscriptionPlan>> getPlans({String currency = 'USD'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/subscription/plans',
        queryParameters: {'currency': currency},
      );
      if (response.statusCode == 200 && response.data != null) {
        final plans = (response.data!['plans'] as List<dynamic>)
            .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
            .toList();
        plans.sort((a, b) => a.tierLevel.compareTo(b.tierLevel));
        return plans;
      }
      throw const ServerFailure('Failed to load subscription plans', code: 'PLANS_FAILED');
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      throw ServerFailure('Error fetching plans: $e', code: 'UNKNOWN_ERROR');
    }
  }

  Future<CurrentSubscription?> getCurrentSubscription() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/subscription/current',
      );
      if (response.statusCode == 200 && response.data != null) {
        final sub = response.data!['subscription'];
        return sub != null ? CurrentSubscription.fromJson(sub as Map<String, dynamic>) : null;
      }
      if (response.statusCode == 404) return null;
      throw const ServerFailure('Failed to load subscription', code: 'SUB_FAILED');
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      return null;
    }
  }

  Future<SubscriptionInitiateResponse> initiateSubscription(String planCode) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/subscription/initiate',
        data: {'plan_code': planCode},
      );
      if (response.statusCode == 200 && response.data != null) {
        return SubscriptionInitiateResponse.fromJson(response.data!);
      }
      throw ServerFailure(
        response.data?['error'] as String? ?? 'Failed to initiate subscription',
        code: 'SUB_INIT_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      throw ServerFailure('Error initiating subscription: $e', code: 'UNKNOWN_ERROR');
    }
  }

  Future<bool> verifyPayment(String reference) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/subscription/verify',
        queryParameters: {'reference': reference},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data!['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> getManageLink() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/subscription/manage-link',
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data!['manage_link'] as String;
      }
      throw const ServerFailure('Failed to get management link', code: 'MANAGE_FAILED');
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      throw ServerFailure('Error getting manage link: $e', code: 'UNKNOWN_ERROR');
    }
  }
}
