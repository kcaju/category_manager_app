import '../../domain/models/category_item.dart';

class CategoryModel extends CategoryItem {
  const CategoryModel({
    required super.id,
    super.userId = 1,
    required super.name,
    super.parentId,
    required super.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int,
      userId: (map['user_id'] as int?) ?? 1,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'user_id': userId,
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

