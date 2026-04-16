import 'package:equatable/equatable.dart';

import 'content.dart';

/// Collection model
/// Represents a user-created collection of content
class Collection extends Equatable {
  const Collection({
    required this.id,
    required this.name,
    required this.userId,
    this.description,
    this.isPublic = false,
    required this.createdAt,
    this.updatedAt,
    this.itemCount = 0,
    this.items = const [],
  });

  final int id;
  final String name;
  final String userId;
  final String? description;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int itemCount;
  final List<Content> items;

  /// Create from JSON
  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as int,
      name: json['name'] as String,
      userId: json['user_id'] as String,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      itemCount: json['item_count'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => Content.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'description': description,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'item_count': itemCount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Copy with new values
  Collection copyWith({
    int? id,
    String? name,
    String? userId,
    String? description,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
    List<Content>? items,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        userId,
        description,
        isPublic,
        createdAt,
        updatedAt,
        itemCount,
        items,
      ];
}

/// Create collection request
class CreateCollectionRequest {
  const CreateCollectionRequest({
    required this.name,
    this.description,
    this.isPublic = false,
  });

  final String name;
  final String? description;
  final bool isPublic;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_public': isPublic,
    };
  }
}

/// Update collection request
class UpdateCollectionRequest {
  const UpdateCollectionRequest({
    this.name,
    this.description,
    this.isPublic,
  });

  final String? name;
  final String? description;
  final bool? isPublic;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (isPublic != null) json['is_public'] = isPublic;
    return json;
  }
}
