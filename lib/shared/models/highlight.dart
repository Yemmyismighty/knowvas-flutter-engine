import 'package:equatable/equatable.dart';

/// Highlight model
class Highlight extends Equatable {
  final int? id;
  final int contentId;
  final int pageNumber;
  final int startPosition;
  final int endPosition;
  final String highlightedText;
  final String color;
  final DateTime createdAt;
  final bool synced;

  const Highlight({
    this.id,
    required this.contentId,
    required this.pageNumber,
    required this.startPosition,
    required this.endPosition,
    required this.highlightedText,
    this.color = '#FFFF00',
    required this.createdAt,
    this.synced = false,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as int?,
      contentId: json['content_id'] as int,
      pageNumber: json['page_number'] as int,
      startPosition: json['start_position'] as int,
      endPosition: json['end_position'] as int,
      highlightedText: json['highlighted_text'] as String,
      color: json['color'] as String? ?? '#FFFF00',
      createdAt: DateTime.parse(json['created_at'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'page_number': pageNumber,
      'start_position': startPosition,
      'end_position': endPosition,
      'highlighted_text': highlightedText,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'synced': synced,
    };
  }

  Highlight copyWith({
    int? id,
    int? contentId,
    int? pageNumber,
    int? startPosition,
    int? endPosition,
    String? highlightedText,
    String? color,
    DateTime? createdAt,
    bool? synced,
  }) {
    return Highlight(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      pageNumber: pageNumber ?? this.pageNumber,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      highlightedText: highlightedText ?? this.highlightedText,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentId,
        pageNumber,
        startPosition,
        endPosition,
        highlightedText,
        color,
        createdAt,
        synced,
      ];
}
