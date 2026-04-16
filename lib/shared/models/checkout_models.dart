// Checkout models matching the web app structure

class CheckoutItem {
  final int id;
  final int resourceId;
  final String resourceType;
  final String title;
  final String author;
  final double price;
  final int quantity;
  final double total;
  final String? imageUrl;

  CheckoutItem({
    required this.id,
    required this.resourceId,
    required this.resourceType,
    required this.title,
    required this.author,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
  });

  factory CheckoutItem.fromJson(Map<String, dynamic> json) {
    return CheckoutItem(
      id: json['id'],
      resourceId: json['resource_id'],
      resourceType: json['resource_type'],
      title: json['title'],
      author: json['author'],
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      total: (json['total'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
    );
  }
}

class CheckoutData {
  final List<CheckoutItem> items;
  final double subtotal;
  final double vatAmount;
  final double vatRate;
  final double total;
  final String currency;
  final bool vatApplied;
  final int itemCount;

  CheckoutData({
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.vatRate,
    required this.total,
    required this.currency,
    required this.vatApplied,
    required this.itemCount,
  });

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    return CheckoutData(
      items: (json['items'] as List)
          .map((item) => CheckoutItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      vatAmount: (json['vat_amount'] ?? 0).toDouble(),
      vatRate: (json['vat_rate'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      vatApplied: json['vat_applied'] ?? false,
      itemCount: json['item_count'] ?? 0,
    );
  }
}

class PaymentInitiateResponse {
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  PaymentInitiateResponse({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  factory PaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiateResponse(
      authorizationUrl: json['authorization_url'],
      accessCode: json['access_code'],
      reference: json['reference'],
    );
  }
}

class PaymentVerificationData {
  final String reference;
  final double amount;
  final String currency;
  final String status;
  final String paidAt;
  final String? channel;
  final String? customerEmail;

  PaymentVerificationData({
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paidAt,
    this.channel,
    this.customerEmail,
  });

  factory PaymentVerificationData.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationData(
      reference: json['reference'],
      amount: (json['amount'] ?? 0).toDouble() / 100, // Convert from kobo/cents
      currency: json['currency'] ?? 'USD',
      status: json['status'],
      paidAt: json['paid_at'],
      channel: json['channel'],
      customerEmail: json['customer_email'],
    );
  }
}
