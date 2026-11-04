import 'package:flutter/material.dart';

import '../../domain/models/category_item.dart';
import '../../domain/models/category_tree_node.dart';

class CategoryTreeNodeWidget extends StatelessWidget {
  final CategoryTreeNode node;
  final Function(int id) onToggleExpansion;
  final Function(CategoryItem parent) onAddSubcategory;
  final Function(CategoryItem item) onDelete;
  final Function(CategoryItem item)? onViewDetails;

  const CategoryTreeNodeWidget({
    super.key,
    required this.node,
    required this.onToggleExpansion,
    required this.onAddSubcategory,
    required this.onDelete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = node.hasChildren;
    final depth = node.depth;
    final leftIndent = (depth * 14.0).clamp(0.0, 90.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          padding: EdgeInsets.only(left: leftIndent),
          child: Row(
            children: [
              // Visual tree branch prefix
              if (depth > 0)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Text(
                    '└──',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

              // Expand / Collapse icon or leaf dot
              InkWell(
                onTap: hasChildren
                    ? () => onToggleExpansion(node.category.id)
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    hasChildren
                        ? (node.isExpanded
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right)
                        : Icons.circle,
                    size: hasChildren ? 22 : 6,
                    color: hasChildren
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),

              const SizedBox(width: 2),

              // Category name & child count badge (Tap to view Relationship Details)
              Expanded(
                child: InkWell(
                  onTap: () => onViewDetails?.call(node.category),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Icon(
                        hasChildren
                            ? (node.isExpanded
                                  ? Icons.folder_open
                                  : Icons.folder)
                            : Icons.label_outline,
                        size: 17,
                        color: hasChildren
                            ? Colors.amber[400]
                            : Colors.blueAccent[100],
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          node.category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: depth == 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (hasChildren) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${node.children.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons (Add Subcategory & Delete)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                color: Colors.greenAccent[400],
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4.0),
                constraints: const BoxConstraints(),
                tooltip: 'Add subcategory under ${node.category.name}',
                onPressed: () => onAddSubcategory(node.category),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.redAccent[200],
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4.0),
                constraints: const BoxConstraints(),
                tooltip: 'Delete ${node.category.name}',
                onPressed: () => onDelete(node.category),
              ),
            ],
          ),
        ),

        // Recursive rendering of children when expanded
        if (hasChildren && node.isExpanded)
          ...node.children.map(
            (child) => CategoryTreeNodeWidget(
              node: child,
              onToggleExpansion: onToggleExpansion,
              onAddSubcategory: onAddSubcategory,
              onDelete: onDelete,
              onViewDetails: onViewDetails,
            ),
          ),
      ],
    );
  }
}
