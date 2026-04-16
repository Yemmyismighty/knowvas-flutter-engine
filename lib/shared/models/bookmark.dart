import 'package:equatable/equatable.dart';

/// Bookmark model
class Bookmark extends Equatable {
  final int? id;
  final int contentId;
  final int pageNumber;
  final String? location;
  final DateTime createdAt;
  final bool synced;

  const Bookmark({
    this.id,
    required this.contentId,
    required this.pageNumber,
    this.location,
    required this.createdAt,
    this.synced = false,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as int?,
      contentId: json['content_id'] as int,
      pageNumber: json['page_number'] as int,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'page_number': pageNumber,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'synced': synced,
    };
  }

  Bookmark copyWith({
    int? id,
    int? contentId,
    int? pageNumber,
    String? location,
    DateTime? createdAt,
    bool? synced,
  }) {
    return Bookmark(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      pageNumber: pageNumber ?? this.pageNumber,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentId,
        pageNumber,
        location,
        createdAt,
        synced,
      ];
}
