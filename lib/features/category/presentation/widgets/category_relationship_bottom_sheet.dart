import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/category_item.dart';
import '../../domain/models/category_search_result.dart';
import '../cubit/category_cubit.dart';
import 'add_category_bottom_sheet.dart';

class CategoryRelationshipBottomSheet extends StatefulWidget {
  final CategoryItem category;
  final List<CategoryItem> availableParents;

  const CategoryRelationshipBottomSheet({
    super.key,
    required this.category,
    required this.availableParents,
  });

  static Future<void> show(
    BuildContext context, {
    required CategoryItem category,
    required List<CategoryItem> availableParents,
  }) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final categoryCubit = context.read<CategoryCubit>();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => BlocProvider.value(
        value: categoryCubit,
        child: CategoryRelationshipBottomSheet(
          category: category,
          availableParents: availableParents,
        ),
      ),
    ).whenComplete(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  State<CategoryRelationshipBottomSheet> createState() =>
      _CategoryRelationshipBottomSheetState();
}

class _CategoryRelationshipBottomSheetState
    extends State<CategoryRelationshipBottomSheet> {
  CategorySearchResult? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final details = await context
        .read<CategoryCubit>()
        .getCategoryDetails(widget.category.id);
    if (mounted) {
      setState(() {
        _details = details;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = widget.category.parentId == null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161622).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header with Category Info & Close
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isRoot
                              ? Colors.tealAccent.withValues(alpha: 0.15)
                              : Colors.blueAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRoot ? Icons.folder_special : Icons.account_tree_outlined,
                          size: 20,
                          color: isRoot ? Colors.tealAccent : const Color(0xFF60A5FA),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isRoot
                                        ? Colors.tealAccent.withValues(alpha: 0.15)
                                        : Colors.blueAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isRoot
                                          ? Colors.tealAccent.withValues(alpha: 0.35)
                                          : Colors.blueAccent.withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    isRoot ? 'Root Category' : 'Subcategory',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isRoot ? Colors.tealAccent : Colors.blueAccent[100],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ID: ${widget.category.id}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Close',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  else if (_details == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Could not load relationship details',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  else ...[
                    // 1. Complete Hierarchy Path (Breadcrumb)
                    Text(
                      'Complete Hierarchy Path',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        _details!.fullHierarchyPath.isNotEmpty
                            ? _details!.fullHierarchyPath.map((c) => c.name).join('  ➔  ')
                            : widget.category.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF60A5FA),
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Parent Category
                    Text(
                      'Parent Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _details!.parent != null ? Icons.folder_outlined : Icons.trip_origin,
                            size: 16,
                            color: _details!.parent != null ? Colors.amber[400] : Colors.tealAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _details!.parent != null
                                  ? '${_details!.parent!.name} (ID: ${_details!.parent!.id})'
                                  : 'None (Top Level Root Category)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _details!.parent != null
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Direct Children
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Direct Children (${_details!.directChildren.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_details!.directChildren.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _details!.directChildren.map((c) {
                          return Chip(
                            avatar: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              child: const Icon(
                                Icons.subdirectory_arrow_right,
                                size: 10,
                                color: Colors.white70,
                              ),
                            ),
                            label: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          );
                        }).toList(),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 15, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 8),
                            Text(
                              'No subcategories (Leaf category)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Actions: Add Subcategory under this category
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              AddCategoryBottomSheet.show(
                                context,
                                initialParent: widget.category,
                                availableParents: widget.availableParents,
                              );
                            },
                            icon: const Icon(Icons.add, size: 17),
                            label: const Text(
                              'Add Subcategory',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

