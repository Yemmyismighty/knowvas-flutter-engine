import 'package:equatable/equatable.dart';
import 'library_item.dart';

/// Library response model
class LibraryResponse extends Equatable {
  final List<LibraryItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const LibraryResponse({
    required this.items,
    required this.totalCount,
    this.page = 1,
    this.pageSize = 20,
  });

  factory LibraryResponse.fromJson(Map<String, dynamic> json) {
    return LibraryResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => [items, totalCount, page, pageSize];
}
