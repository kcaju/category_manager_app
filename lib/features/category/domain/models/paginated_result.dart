import 'package:equatable/equatable.dart';

class PaginatedResult<T> extends Equatable {
  final int page;
  final int pageSize;
  final int totalCount;
  final List<T> items;

  const PaginatedResult({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.items,
  });

  int get totalPages => (pageSize <= 0 || totalCount <= 0) ? 1 : (totalCount / pageSize).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'page_size': pageSize,
      'total_count': totalCount,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, totalCount, items];
}

