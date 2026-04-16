import 'package:equatable/equatable.dart';
import 'content.dart';

/// Cart item model
class CartItem extends Equatable {
  final Content content;
  final DateTime addedAt;

  const CartItem({
    required this.content,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      content: Content.fromJson(json['content'] as Map<String, dynamic>),
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.toJson(),
      'added_at': addedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [content, addedAt];
}

/// Cart response model
class CartResponse extends Equatable {
  final List<CartItem> items;
  final Map<String, double> totalPrice;

  const CartResponse({
    required this.items,
    required this.totalPrice,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (json['total_price'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total_price': totalPrice,
    };
  }

  @override
  List<Object?> get props => [items, totalPrice];
}
