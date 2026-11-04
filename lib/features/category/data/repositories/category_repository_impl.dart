import '../../domain/models/category_item.dart';
import '../../domain/models/category_search_result.dart';
import '../../domain/models/category_tree_node.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;

  CategoryRepositoryImpl({required this.localDataSource});

  @override
  Future<CategoryItem> createCategory({
    required String name,
    int? parentId,
    int? userId,
  }) async {
    return await localDataSource.insertCategory(
      name,
      parentId,
      userId: userId ?? 1,
    );
  }

  @override
  Future<List<CategoryItem>> getAllCategoriesFlat({int? userId}) async {
    return await localDataSource.getAllCategories(userId: userId);
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree({int? userId}) async {
    final allItems = await localDataSource.getAllCategories(userId: userId);
    return _buildHierarchyTree(allItems);
  }

  /// Transforms a flat list of categories into a recursive tree structure (O(N) complexity)
  List<CategoryTreeNode> _buildHierarchyTree(List<CategoryItem> items) {
    if (items.isEmpty) return [];

    // Group items by parent_id
    final Map<int?, List<CategoryItem>> childrenMap = {};
    for (final item in items) {
      childrenMap.putIfAbsent(item.parentId, () => []).add(item);
    }

    // Roots are items with parentId == null
    final rootItems = childrenMap[null] ?? [];

    // Recursively build tree nodes
    CategoryTreeNode buildNode(CategoryItem current, int depth, CategoryItem? parent) {
      final children = childrenMap[current.id] ?? [];
      final childNodes = children
          .map((child) => buildNode(child, depth + 1, current))
          .toList();

      return CategoryTreeNode(
        category: current,
        children: childNodes,
        depth: depth,
        parent: parent,
        isExpanded: false, // Start collapsed until user clicks to expand
      );
    }

    return rootItems.map((root) => buildNode(root, 0, null)).toList();
  }

  @override
  Future<PaginatedResult<CategorySearchResult>> searchCategories({
    required String query,
    int? limit,
    int page = 1,
    int pageSize = 20,
    int? userId,
  }) async {
    int? effectiveLimit = limit;
    int? effectiveOffset;

    final totalCount = await localDataSource.countSearchResults(
      query,
      userId: userId,
    );

    if (limit != null) {
      // Explicit limit mode (e.g. limit = 5, 10, 20) -> returns up to limit records
      effectiveLimit = limit;
      effectiveOffset = 0;
    } else {
      // Limit not provided ("All") -> return ALL matching results as per PDF specification
      effectiveLimit = null;
      effectiveOffset = null;
    }

    final matchedCategories = await localDataSource.searchCategoriesByName(
      query,
      limit: effectiveLimit,
      offset: effectiveOffset,
      userId: userId,
    );

    final List<CategorySearchResult> results = [];

    for (final cat in matchedCategories) {
      CategoryItem? parent;
      if (cat.parentId != null) {
        parent = await localDataSource.getCategoryById(cat.parentId!, userId: cat.userId);
      }

      final directChildren = await localDataSource.getDirectChildren(cat.id, userId: cat.userId);
      final ancestors = await localDataSource.getAncestors(cat.id, userId: cat.userId);

      results.add(
        CategorySearchResult(
          category: cat,
          parent: parent,
          directChildren: directChildren,
          fullHierarchyPath: ancestors,
        ),
      );
    }

    return PaginatedResult<CategorySearchResult>(
      page: page,
      pageSize: effectiveLimit ?? (totalCount > 0 ? totalCount : 1),
      totalCount: totalCount,
      items: results,
    );
  }

  @override
  Future<CategorySearchResult> getCategoryDetails(int id, {int? userId}) async {
    final cat = await localDataSource.getCategoryById(id, userId: userId);
    if (cat == null) {
      throw Exception('Category not found');
    }

    CategoryItem? parent;
    if (cat.parentId != null) {
      parent = await localDataSource.getCategoryById(cat.parentId!, userId: cat.userId);
    }

    final directChildren = await localDataSource.getDirectChildren(cat.id, userId: cat.userId);
    final ancestors = await localDataSource.getAncestors(cat.id, userId: cat.userId);

    return CategorySearchResult(
      category: cat,
      parent: parent,
      directChildren: directChildren,
      fullHierarchyPath: ancestors,
    );
  }

  @override
  Future<void> deleteCategory(int id, {int? userId}) async {
    await localDataSource.deleteCategory(id, userId: userId);
  }

  @override
  Future<void> seedDefaultCategories({int? userId}) async {
    await localDataSource.seedDefaultCategories(userId: userId ?? 1);
  }

  @override
  Future<void> clearAllCategories({int? userId}) async {
    await localDataSource.clearAllCategories(userId: userId);
  }
}
