import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/models/category_search_result.dart';

class SearchResultCard extends StatelessWidget {
  final CategorySearchResult result;

  const SearchResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final cat = result.category;
    final parent = result.parent;
    final children = result.directChildren;
    final fullPath = result.fullHierarchyPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Name & Tag
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.category_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: parent == null
                          ? Colors.tealAccent.withValues(alpha: 0.15)
                          : Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: parent == null
                            ? Colors.tealAccent.withValues(alpha: 0.3)
                            : Colors.blueAccent.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      parent == null ? 'Root Category' : 'Subcategory',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: parent == null ? Colors.tealAccent : Colors.blueAccent[100],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 10),

              // 1. Complete Hierarchy Path
              Text(
                'Complete Hierarchy Path:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  fullPath.isNotEmpty
                      ? fullPath.map((c) => c.name).join('  ➔  ')
                      : cat.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF60A5FA),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Parent Category
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text(
                    'Parent Category:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    parent != null ? parent.name : 'None (Top Level)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: parent != null ? Colors.white : Colors.white38,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 3. Direct Children
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Children:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  children.isNotEmpty
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: children.map((c) {
                            return Chip(
                              label: Text(
                                c.name,
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            );
                          }).toList(),
                        )
                      : const Text(
                          'No subcategories',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
