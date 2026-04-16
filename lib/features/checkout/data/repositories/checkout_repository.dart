import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/core/errors/exceptions.dart';
import 'package:knowvas/core/errors/failures.dart';
import 'package:knowvas/shared/models/checkout_models.dart';

class CheckoutRepository {
  CheckoutRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CheckoutData> getCheckoutData() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/purchase/checkout',
      );
      if (response.statusCode == 200 && response.data != null) {
        return CheckoutData.fromJson(response.data!['data'] as Map<String, dynamic>);
      }
      throw ServerFailure(
        response.data?['error'] as String? ?? 'Failed to load checkout data',
        code: 'CHECKOUT_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      throw ServerFailure('Error fetching checkout data: $e', code: 'UNKNOWN_ERROR');
    }
  }

  Future<PaymentInitiateResponse> initiatePayment() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/purchase/initiate-payment',
      );
      if (response.statusCode == 200 && response.data != null) {
        return PaymentInitiateResponse.fromJson(response.data!['data'] as Map<String, dynamic>);
      }
      throw ServerFailure(
        response.data?['error'] as String? ?? 'Failed to initiate payment',
        code: 'PAYMENT_INIT_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      throw ServerFailure('Error initiating payment: $e', code: 'UNKNOWN_ERROR');
    }
  }

  Future<PaymentVerificationData> verifyPayment(String reference) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/purchase/verify-payment',
        queryParameters: {'reference': reference},
      );
      if (response.statusCode == 200 && response.data != null) {
        return PaymentVerificationData.fromJson(response.data!['data'] as Map<String, dynamic>);
      }
      throw ServerFailure(
        response.data?['error'] as String? ?? 'Failed to verify payment',
        code: 'PAYMENT_VERIFY_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      throw ServerFailure('Error verifying payment: $e', code: 'UNKNOWN_ERROR');
    }
  }
}
