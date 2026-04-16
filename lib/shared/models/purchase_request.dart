import 'package:equatable/equatable.dart';

/// Purchase request model
class PurchaseRequest extends Equatable {
  final List<int> contentIds;
  final String currency;
  final String paymentMethod;

  const PurchaseRequest({
    required this.contentIds,
    required this.currency,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'content_ids': contentIds,
      'currency': currency,
      'payment_method': paymentMethod,
    };
  }

  @override
  List<Object?> get props => [contentIds, currency, paymentMethod];
}

/// Purchase response model
class PurchaseResponse extends Equatable {
  final String transactionId;
  final List<int> purchasedContentIds;
  final double totalAmount;
  final String currency;
  final DateTime purchaseDate;
  final String status;

  const PurchaseResponse({
    required this.transactionId,
    required this.purchasedContentIds,
    required this.totalAmount,
    required this.currency,
    required this.purchaseDate,
    required this.status,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      transactionId: json['transaction_id'] as String,
      purchasedContentIds: (json['purchased_content_ids'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'purchased_content_ids': purchasedContentIds,
      'total_amount': totalAmount,
      'currency': currency,
      'purchase_date': purchaseDate.toIso8601String(),
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        transactionId,
        purchasedContentIds,
        totalAmount,
        currency,
        purchaseDate,
        status,
      ];
}
