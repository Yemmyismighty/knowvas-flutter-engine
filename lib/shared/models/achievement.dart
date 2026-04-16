import 'package:equatable/equatable.dart';

/// Achievement model representing user achievements
class Achievement extends Equatable {
  final int id;
  final String name;
  final String description;
  final String iconUrl;
  final String category;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String,
      category: json['category'] as String,
      targetValue: json['target_value'] as int,
      currentValue: json['current_value'] as int? ?? 0,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'category': category,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_unlocked': isUnlocked,
      if (unlockedAt != null) 'unlocked_at': unlockedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Achievement copyWith({
    int? id,
    String? name,
    String? description,
    String? iconUrl,
    String? category,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Get progress as percentage (0 to 100)
  int get progressPercentage {
    return (progress * 100).round();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        category,
        targetValue,
        currentValue,
        isUnlocked,
        unlockedAt,
        createdAt,
      ];
}
