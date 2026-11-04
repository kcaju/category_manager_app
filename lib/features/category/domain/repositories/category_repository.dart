import '../models/category_item.dart';
import '../models/category_search_result.dart';
import '../models/category_tree_node.dart';
import '../models/paginated_result.dart';

abstract class CategoryRepository {
  Future<CategoryItem> createCategory({
    required String name,
    int? parentId,
    int? userId,
  });

  Future<List<CategoryTreeNode>> getCategoryTree({int? userId});

  Future<PaginatedResult<CategorySearchResult>> searchCategories({
    required String query,
    int? limit,
    int page = 1,
    int pageSize = 20,
    int? userId,
  });

  Future<List<CategoryItem>> getAllCategoriesFlat({int? userId});

  Future<CategorySearchResult> getCategoryDetails(int id, {int? userId});

  Future<void> deleteCategory(int id, {int? userId});

  Future<void> seedDefaultCategories({int? userId});

  Future<void> clearAllCategories({int? userId});
}
