import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/subscription.dart';

/// Repository for subscription operations
/// Handles fetching plans, subscribing, and managing active subscriptions
class SubscriptionRepository {
  SubscriptionRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get all available subscription plans
  /// Returns list of SubscriptionPlan
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.subscriptionPlans,
      );

      if (response.statusCode == 200 && response.data != null) {
        final plans = response.data!['plans'] as List<dynamic>;
        return plans
            .map((plan) => SubscriptionPlan.fromJson(plan as Map<String, dynamic>))
            .toList();
      } else {
        throw const ServerFailure(
          'Failed to fetch subscription plans',
          code: 'PLANS_FETCH_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching subscription plans: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Subscribe to a plan
  /// Returns ActiveSubscription on success
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<ActiveSubscription> subscribe({
    required String planId,
    required String billingCycle, // 'monthly' or 'annual'
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.subscribe,
        data: {
          'plan_id': planId,
          'billing_cycle': billingCycle,
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return ActiveSubscription.fromJson(
            response.data!['subscription'] as Map<String, dynamic>,
          );
        }
      }

      throw const ServerFailure(
        'Failed to subscribe to plan',
        code: 'SUBSCRIBE_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while subscribing: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get active subscription for current user
  /// Returns ActiveSubscription if user has active subscription
  /// Returns null if no active subscription
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<ActiveSubscription?> getActiveSubscription() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.activeSubscription,
      );

      if (response.statusCode == 200 && response.data != null) {
        final subscription = response.data!['subscription'];
        if (subscription != null) {
          return ActiveSubscription.fromJson(
            subscription as Map<String, dynamic>,
          );
        }
        return null;
      } else if (response.statusCode == 404) {
        // No active subscription
        return null;
      } else {
        throw const ServerFailure(
          'Failed to fetch active subscription',
          code: 'SUBSCRIPTION_FETCH_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      // 404 means no active subscription
      if (e.statusCode == 404) {
        return null;
      }
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while fetching active subscription: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Cancel active subscription
  /// Returns updated ActiveSubscription with cancelled status
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<ActiveSubscription> cancelSubscription() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.cancelSubscription,
        data: {},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ActiveSubscription.fromJson(
          response.data!['subscription'] as Map<String, dynamic>,
        );
      } else {
        throw const ServerFailure(
          'Failed to cancel subscription',
          code: 'CANCEL_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred while cancelling subscription: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}
