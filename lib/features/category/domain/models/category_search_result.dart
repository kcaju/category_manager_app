import 'package:equatable/equatable.dart';
import 'category_item.dart';

class CategorySearchResult extends Equatable {
  final CategoryItem category;
  final CategoryItem? parent;
  final List<CategoryItem> directChildren;
  final List<CategoryItem> fullHierarchyPath;

  const CategorySearchResult({
    required this.category,
    this.parent,
    this.directChildren = const [],
    this.fullHierarchyPath = const [],
  });

  /// Formats the complete hierarchy/path as "Electronics > Mobile > Android > Samsung"
  String get formattedPath {
    if (fullHierarchyPath.isEmpty) return category.name;
    return fullHierarchyPath.map((c) => c.name).join(' > ');
  }

  @override
  List<Object?> get props => [
        category,
        parent,
        directChildren,
        fullHierarchyPath,
      ];
}

