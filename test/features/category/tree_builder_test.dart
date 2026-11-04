import 'package:flutter_test/flutter_test.dart';
import 'package:category_manager_app/features/category/data/datasources/category_local_data_source.dart';
import 'package:category_manager_app/features/category/data/repositories/category_repository_impl.dart';
import 'package:category_manager_app/features/category/data/models/category_model.dart';

class MockCategoryLocalDataSource implements CategoryLocalDataSource {
  final List<CategoryModel> _items = [];

  @override
  Future<CategoryModel> insertCategory(
    String name,
    int? parentId, {
    int userId = 1,
  }) async {
    final userItems = _items.where((c) => c.userId == userId);
    final maxId = userItems.isEmpty
        ? 0
        : userItems.map((c) => c.id).reduce((a, b) => a > b ? a : b);
    final model = CategoryModel(
      id: maxId + 1,
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
      userId: userId,
    );
    _items.add(model);
    return model;
  }

  @override
  Future<bool> isDuplicateNameUnderParent(
    String name,
    int? parentId, {
    int userId = 1,
  }) async {
    return _items.any((c) =>
        c.userId == userId &&
        (c.parentId ?? 0) == (parentId ?? 0) &&
        c.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  @override
  Future<List<CategoryModel>> getAllCategories({int? userId}) async {
    if (userId != null) {
      return List.unmodifiable(_items.where((c) => c.userId == userId));
    }
    return List.unmodifiable(_items);
  }

  @override
  Future<CategoryModel?> getCategoryById(int id, {int? userId}) async =>
      _items.where((c) => c.id == id && (userId == null || c.userId == userId)).firstOrNull;

  @override
  Future<List<CategoryModel>> getDirectChildren(int parentId, {int? userId}) async =>
      _items.where((c) => c.parentId == parentId && (userId == null || c.userId == userId)).toList();

  @override
  Future<List<CategoryModel>> getAncestors(int categoryId, {int? userId}) async {
    final List<CategoryModel> path = [];
    int? currentId = categoryId;
    while (currentId != null) {
      final current = await getCategoryById(currentId, userId: userId);
      if (current == null) break;
      path.insert(0, current);
      currentId = current.parentId;
    }
    return path;
  }

  @override
  Future<List<CategoryModel>> searchCategoriesByName(
    String query, {
    int? limit,
    int? offset,
    int? userId,
  }) async {
    var matched = _items
        .where((c) =>
            (userId == null || c.userId == userId) &&
            c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (offset != null) {
      return matched.skip(offset).take(limit ?? matched.length).toList();
    }
    if (limit != null) {
      return matched.take(limit).toList();
    }
    return matched;
  }

  @override
  Future<int> countSearchResults(String query, {int? userId}) async {
    return _items
        .where((c) =>
            (userId == null || c.userId == userId) &&
            c.name.toLowerCase().contains(query.toLowerCase()))
        .length;
  }

  @override
  Future<void> deleteCategory(int id, {int? userId}) async {
    final idsToDelete = <int>{id};
    bool added;
    do {
      added = false;
      for (final item in _items) {
        if (userId != null && item.userId != userId) continue;
        if (item.parentId != null && idsToDelete.contains(item.parentId)) {
          if (idsToDelete.add(item.id)) added = true;
        }
      }
    } while (added);
    _items.removeWhere((c) => (userId == null || c.userId == userId) && idsToDelete.contains(c.id));
  }

  @override
  Future<void> clearAllCategories({int? userId}) async {
    if (userId != null) {
      _items.removeWhere((c) => c.userId == userId);
    } else {
      _items.clear();
    }
  }

  @override
  Future<void> seedDefaultCategories({int userId = 1}) async {}
}

void main() {
  late MockCategoryLocalDataSource mockDataSource;
  late CategoryRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockCategoryLocalDataSource();
    repository = CategoryRepositoryImpl(localDataSource: mockDataSource);
  });

  test('Hierarchical Tree Building supports unlimited depth (A -> B -> C -> D -> E -> F)', () async {
    // Insert deep chain
    final a = await mockDataSource.insertCategory('A', null);
    final b = await mockDataSource.insertCategory('B', a.id);
    final c = await mockDataSource.insertCategory('C', b.id);
    final d = await mockDataSource.insertCategory('D', c.id);
    final e = await mockDataSource.insertCategory('E', d.id);
    await mockDataSource.insertCategory('F', e.id);

    final tree = await repository.getCategoryTree();

    expect(tree.length, 1);
    expect(tree.first.category.name, 'A');
    expect(tree.first.depth, 0);

    final bNode = tree.first.children.first;
    expect(bNode.category.name, 'B');
    expect(bNode.depth, 1);

    final cNode = bNode.children.first;
    expect(cNode.category.name, 'C');
    expect(cNode.depth, 2);

    final dNode = cNode.children.first;
    expect(dNode.category.name, 'D');
    expect(dNode.depth, 3);

    final eNode = dNode.children.first;
    expect(eNode.category.name, 'E');
    expect(eNode.depth, 4);

    final fNode = eNode.children.first;
    expect(fNode.category.name, 'F');
    expect(fNode.depth, 5);
  });

  test('Recursive search returns complete ancestry path and direct children', () async {
    final electronics = await mockDataSource.insertCategory('Electronics', null);
    final mobile = await mockDataSource.insertCategory('Mobile', electronics.id);
    final android = await mockDataSource.insertCategory('Android', mobile.id);
    await mockDataSource.insertCategory('Samsung', android.id);
    await mockDataSource.insertCategory('OnePlus', android.id);

    final searchResult = await repository.searchCategories(query: 'Samsung');

    expect(searchResult.items.length, 1);
    final result = searchResult.items.first;

    expect(result.category.name, 'Samsung');
    expect(result.parent?.name, 'Android');
    expect(result.formattedPath, 'Electronics > Mobile > Android > Samsung');
  });

  test('Each user starts from ID 1 when creating categories from scratch', () async {
    // User 1 creates categories
    final u1Cat1 = await mockDataSource.insertCategory('U1 Root', null, userId: 1);
    final u1Cat2 = await mockDataSource.insertCategory('U1 Sub', u1Cat1.id, userId: 1);
    expect(u1Cat1.id, 1);
    expect(u1Cat2.id, 2);

    // User 2 creates categories from scratch -> MUST start from ID 1
    final u2Cat1 = await mockDataSource.insertCategory('U2 Root', null, userId: 2);
    final u2Cat2 = await mockDataSource.insertCategory('U2 Sub', u2Cat1.id, userId: 2);
    expect(u2Cat1.id, 1);
    expect(u2Cat2.id, 2);

    // User 3 creates category from scratch -> MUST start from ID 1
    final u3Cat1 = await mockDataSource.insertCategory('U3 Root', null, userId: 3);
    expect(u3Cat1.id, 1);
  });

  test('Duplicate detection: same name under different parent is allowed', () async {
    final electronics = await mockDataSource.insertCategory('Electronics', null);
    final clothing = await mockDataSource.insertCategory('Clothing', null);

    // Both can have 'Mobile' as child
    final mobile1 = await mockDataSource.insertCategory('Mobile', electronics.id);
    final mobile2 = await mockDataSource.insertCategory('Mobile', clothing.id);

    expect(mobile1.name, 'Mobile');
    expect(mobile2.name, 'Mobile');
    expect(mobile1.parentId, electronics.id);
    expect(mobile2.parentId, clothing.id);

    // Checking duplicate under electronics for 'Mobile' returns true
    final isDup = await mockDataSource.isDuplicateNameUnderParent('Mobile', electronics.id);
    expect(isDup, isTrue);

    // Checking duplicate under clothing for 'Jeans' returns false
    final isNotDup = await mockDataSource.isDuplicateNameUnderParent('Jeans', clothing.id);
    expect(isNotDup, isFalse);
  });

  test('Search limit parameter: returns limited results when provided, and all results when null', () async {
    for (int i = 1; i <= 6; i++) {
      await mockDataSource.insertCategory('Item $i', null);
    }

    // Limit = 2
    final limited = await repository.searchCategories(query: 'Item', limit: 2);
    expect(limited.items.length, 2);

    // Limit = null (All)
    final all = await repository.searchCategories(query: 'Item', limit: null);
    expect(all.items.length, 6);
  });
}
