import 'package:equatable/equatable.dart';

class CategoryItem extends Equatable {
  final int id;
  final int userId;
  final String name;
  final int? parentId;
  final DateTime createdAt;

  const CategoryItem({
    required this.id,
    this.userId = 1,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  bool get isRoot => parentId == null;

  CategoryItem copyWith({
    int? id,
    int? userId,
    String? name,
    int? parentId,
    DateTime? createdAt,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, parentId, createdAt];
}

