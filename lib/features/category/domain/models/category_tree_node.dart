import 'package:equatable/equatable.dart';
import 'category_item.dart';

class CategoryTreeNode extends Equatable {
  final CategoryItem category;
  final List<CategoryTreeNode> children;
  final bool isExpanded;
  final int depth;
  final CategoryItem? parent;

  const CategoryTreeNode({
    required this.category,
    this.children = const [],
    this.isExpanded = false,
    this.depth = 0,
    this.parent,
  });

  bool get hasChildren => children.isNotEmpty;

  CategoryTreeNode copyWith({
    CategoryItem? category,
    List<CategoryTreeNode>? children,
    bool? isExpanded,
    int? depth,
    CategoryItem? parent,
  }) {
    return CategoryTreeNode(
      category: category ?? this.category,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      depth: depth ?? this.depth,
      parent: parent ?? this.parent,
    );
  }

  /// Recursively find a node by category ID and toggle its expansion state
  CategoryTreeNode toggleExpansion(int targetId) {
    if (category.id == targetId) {
      return copyWith(isExpanded: !isExpanded);
    }
    return copyWith(
      children: children.map((c) => c.toggleExpansion(targetId)).toList(),
    );
  }

  /// Recursively expand or collapse all nodes
  CategoryTreeNode setExpansionAll(bool expanded) {
    return copyWith(
      isExpanded: expanded,
      children: children.map((c) => c.setExpansionAll(expanded)).toList(),
    );
  }

  @override
  List<Object?> get props => [category, children, isExpanded, depth, parent];
}

