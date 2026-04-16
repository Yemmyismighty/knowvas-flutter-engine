import 'package:equatable/equatable.dart';

/// Note model
class Note extends Equatable {
  final int? id;
  final int contentId;
  final int pageNumber;
  final int? position;
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const Note({
    this.id,
    required this.contentId,
    required this.pageNumber,
    this.position,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int?,
      contentId: json['content_id'] as int,
      pageNumber: json['page_number'] as int,
      position: json['position'] as int?,
      noteText: json['note_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'page_number': pageNumber,
      'position': position,
      'note_text': noteText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  Note copyWith({
    int? id,
    int? contentId,
    int? pageNumber,
    int? position,
    String? noteText,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Note(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      pageNumber: pageNumber ?? this.pageNumber,
      position: position ?? this.position,
      noteText: noteText ?? this.noteText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentId,
        pageNumber,
        position,
        noteText,
        createdAt,
        updatedAt,
        synced,
      ];
}
