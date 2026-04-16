import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/library_item.dart';

/// Repository for purchase operations
/// Handles purchasing content and processing payments
class PurchaseRepository {
  PurchaseRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Purchase content from cart
  /// 
  /// Makes a POST request to /api/purchase with:
  /// - content_id: ID of the content to purchase
  /// - currency: Currency code (e.g., 'USD', 'NGN')
  /// - payment_method: Payment method identifier
  /// 
  /// Returns PurchaseResponse with purchased items
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  /// Throws PaymentFailure on payment processing errors
  Future<PurchaseResponse> purchase({
    required int contentId,
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.purchase,
        data: {
          'content_id': contentId,
          'currency': currency,
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return PurchaseResponse.fromJson(response.data!);
        }
      }

      throw const ServerFailure(
        'Failed to complete purchase',
        code: 'PURCHASE_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      // Check if it's a payment-specific error
      if (e.code == 'PAYMENT_FAILED' || 
          e.code == 'INSUFFICIENT_FUNDS' ||
          e.code == 'PAYMENT_DECLINED') {
        throw PaymentFailure(
          e.message,
          statusCode: e.statusCode,
          code: e.code,
        );
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
        'An unexpected error occurred during purchase: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Purchase all items in cart
  /// 
  /// Makes a POST request to /api/purchase with:
  /// - currency: Currency code (e.g., 'USD', 'NGN')
  /// - payment_method: Payment method identifier
  /// 
  /// Returns PurchaseResponse with all purchased items
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  /// Throws PaymentFailure on payment processing errors
  Future<PurchaseResponse> purchaseCart({
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.purchase,
        data: {
          'currency': currency,
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return PurchaseResponse.fromJson(response.data!);
        }
      }

      throw const ServerFailure(
        'Failed to complete purchase',
        code: 'PURCHASE_FAILED',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      // Check if it's a payment-specific error
      if (e.code == 'PAYMENT_FAILED' || 
          e.code == 'INSUFFICIENT_FUNDS' ||
          e.code == 'PAYMENT_DECLINED') {
        throw PaymentFailure(
          e.message,
          statusCode: e.statusCode,
          code: e.code,
        );
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
        'An unexpected error occurred during purchase: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}

/// Purchase response model
class PurchaseResponse {
  final bool success;
  final String message;
  final List<LibraryItem> purchasedItems;
  final String? transactionId;

  const PurchaseResponse({
    required this.success,
    required this.message,
    required this.purchasedItems,
    this.transactionId,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Purchase completed',
      purchasedItems: (json['purchased_items'] as List<dynamic>?)
              ?.map((item) => LibraryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      transactionId: json['transaction_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'purchased_items': purchasedItems.map((item) => item.toJson()).toList(),
      'transaction_id': transactionId,
    };
  }
}
