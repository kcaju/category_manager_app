import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<CategoryModel> insertCategory(
    String name,
    int? parentId, {
    int userId = 1,
  });
  Future<bool> isDuplicateNameUnderParent(
    String name,
    int? parentId, {
    int userId = 1,
  });
  Future<List<CategoryModel>> getAllCategories({int? userId});
  Future<CategoryModel?> getCategoryById(int id, {int? userId});
  Future<List<CategoryModel>> getDirectChildren(int parentId, {int? userId});
  Future<List<CategoryModel>> getAncestors(int categoryId, {int? userId});
  Future<List<CategoryModel>> searchCategoriesByName(
    String query, {
    int? limit,
    int? offset,
    int? userId,
  });
  Future<int> countSearchResults(String query, {int? userId});
  Future<void> deleteCategory(int id, {int? userId});
  Future<void> seedDefaultCategories({int userId = 1});
  Future<void> clearAllCategories({int? userId});
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final AppDatabase databaseHelper;

  CategoryLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<bool> isDuplicateNameUnderParent(
    String name,
    int? parentId, {
    int userId = 1,
  }) async {
    final db = await databaseHelper.database;
    final parentKey = parentId ?? 0;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${AppConstants.categoriesTable}
      WHERE user_id = ? AND IFNULL(parent_id, 0) = ? AND LOWER(name) = LOWER(?)
      ''',
      [userId, parentKey, name.trim()],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  @override
  Future<CategoryModel> insertCategory(
    String name,
    int? parentId, {
    int userId = 1,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Category name cannot be empty');
    }

    final isDuplicate = await isDuplicateNameUnderParent(
      trimmedName,
      parentId,
      userId: userId,
    );
    if (isDuplicate) {
      if (parentId == null) {
        throw ValidationFailure(
          'A root category named "$trimmedName" already exists.',
        );
      } else {
        throw ValidationFailure(
          'A subcategory named "$trimmedName" already exists under this parent.',
        );
      }
    }

    final db = await databaseHelper.database;
    final now = DateTime.now();

    // Query next sequential ID for THIS specific user (starts at 1 for each user)
    final nextIdResult = await db.rawQuery(
      'SELECT IFNULL(MAX(id), 0) + 1 as next_id FROM ${AppConstants.categoriesTable} WHERE user_id = ?',
      [userId],
    );
    final nextId = Sqflite.firstIntValue(nextIdResult) ?? 1;

    final model = CategoryModel(
      id: nextId,
      userId: userId,
      name: trimmedName,
      parentId: parentId,
      createdAt: now,
    );

    await db.insert(
      AppConstants.categoriesTable,
      model.toMap(),
    );

    return model;
  }

  @override
  Future<List<CategoryModel>> getAllCategories({int? userId}) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      AppConstants.categoriesTable,
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'parent_id ASC, name ASC',
    );
    return results.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(int id, {int? userId}) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      AppConstants.categoriesTable,
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return CategoryModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<CategoryModel>> getDirectChildren(int parentId, {int? userId}) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      AppConstants.categoriesTable,
      where: userId != null ? 'parent_id = ? AND user_id = ?' : 'parent_id = ?',
      whereArgs: userId != null ? [parentId, userId] : [parentId],
      orderBy: 'name ASC',
    );
    return results.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<List<CategoryModel>> getAncestors(int categoryId, {int? userId}) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> results;
    if (userId != null) {
      results = await db.rawQuery(
        '''
        WITH RECURSIVE category_path AS (
          SELECT id, user_id, name, parent_id, created_at, 1 as level
          FROM ${AppConstants.categoriesTable}
          WHERE id = ? AND user_id = ?
          UNION ALL
          SELECT c.id, c.user_id, c.name, c.parent_id, c.created_at, cp.level + 1
          FROM ${AppConstants.categoriesTable} c
          JOIN category_path cp ON c.id = cp.parent_id AND c.user_id = cp.user_id
        )
        SELECT id, user_id, name, parent_id, created_at FROM category_path ORDER BY level DESC;
        ''',
        [categoryId, userId],
      );
    } else {
      results = await db.rawQuery(
        '''
        WITH RECURSIVE category_path AS (
          SELECT id, user_id, name, parent_id, created_at, 1 as level
          FROM ${AppConstants.categoriesTable}
          WHERE id = ?
          UNION ALL
          SELECT c.id, c.user_id, c.name, c.parent_id, c.created_at, cp.level + 1
          FROM ${AppConstants.categoriesTable} c
          JOIN category_path cp ON c.id = cp.parent_id AND c.user_id = cp.user_id
        )
        SELECT id, user_id, name, parent_id, created_at FROM category_path ORDER BY level DESC;
        ''',
        [categoryId],
      );
    }

    return results.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<List<CategoryModel>> searchCategoriesByName(
    String query, {
    int? limit,
    int? offset,
    int? userId,
  }) async {
    final db = await databaseHelper.database;
    final searchPattern = '%${query.trim().toLowerCase()}%';

    String sql = '''
      SELECT * FROM ${AppConstants.categoriesTable}
      WHERE ${userId != null ? 'user_id = ? AND ' : ''}LOWER(name) LIKE ?
      ORDER BY name ASC
    ''';

    final List<dynamic> args = [];
    if (userId != null) args.add(userId);
    args.add(searchPattern);

    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
      if (offset != null) {
        sql += ' OFFSET ?';
        args.add(offset);
      }
    }

    final results = await db.rawQuery(sql, args);
    return results.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<int> countSearchResults(String query, {int? userId}) async {
    final db = await databaseHelper.database;
    final searchPattern = '%${query.trim().toLowerCase()}%';
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${AppConstants.categoriesTable}
      WHERE ${userId != null ? 'user_id = ? AND ' : ''}LOWER(name) LIKE ?
      ''',
      [if (userId != null) userId, searchPattern],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> deleteCategory(int id, {int? userId}) async {
    final db = await databaseHelper.database;
    if (userId != null) {
      await db.rawDelete(
        '''
        WITH RECURSIVE to_delete AS (
          SELECT id FROM ${AppConstants.categoriesTable} WHERE id = ? AND user_id = ?
          UNION ALL
          SELECT c.id FROM ${AppConstants.categoriesTable} c
          JOIN to_delete td ON c.parent_id = td.id AND c.user_id = ?
        )
        DELETE FROM ${AppConstants.categoriesTable}
        WHERE user_id = ? AND id IN (SELECT id FROM to_delete);
        ''',
        [id, userId, userId, userId],
      );
    } else {
      await db.rawDelete(
        '''
        WITH RECURSIVE to_delete AS (
          SELECT id, user_id FROM ${AppConstants.categoriesTable} WHERE id = ?
          UNION ALL
          SELECT c.id, c.user_id FROM ${AppConstants.categoriesTable} c
          JOIN to_delete td ON c.parent_id = td.id AND c.user_id = td.user_id
        )
        DELETE FROM ${AppConstants.categoriesTable}
        WHERE id IN (SELECT id FROM to_delete);
        ''',
        [id],
      );
    }
  }

  @override
  Future<void> clearAllCategories({int? userId}) async {
    final db = await databaseHelper.database;
    if (userId != null) {
      await db.delete(
        AppConstants.categoriesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      await db.delete(AppConstants.categoriesTable);
    }
  }

  @override
  Future<void> seedDefaultCategories({int userId = 1}) async {
    final existing = await getAllCategories(userId: userId);
    if (existing.isNotEmpty) return; // Already seeded

    // 1. Electronics hierarchy
    final electronics = await insertCategory('Electronics', null, userId: userId);
    final mobile = await insertCategory('Mobile', electronics.id, userId: userId);
    final android = await insertCategory('Android', mobile.id, userId: userId);
    await insertCategory('Samsung', android.id, userId: userId);
    await insertCategory('OnePlus', android.id, userId: userId);
    await insertCategory('iPhone', mobile.id, userId: userId);

    final laptop = await insertCategory('Laptop', electronics.id, userId: userId);
    await insertCategory('Gaming', laptop.id, userId: userId);

    // 2. Clothing hierarchy
    final clothing = await insertCategory('Clothing', null, userId: userId);
    await insertCategory('Mobile Accessories', clothing.id, userId: userId);
    await insertCategory('Men', clothing.id, userId: userId);
    await insertCategory('Women', clothing.id, userId: userId);

    // 3. Deep chain test (A -> B -> C -> D -> E -> F)
    final a = await insertCategory('Chain-A', null, userId: userId);
    final b = await insertCategory('Chain-B', a.id, userId: userId);
    final c = await insertCategory('Chain-C', b.id, userId: userId);
    final d = await insertCategory('Chain-D', c.id, userId: userId);
    final e = await insertCategory('Chain-E', d.id, userId: userId);
    await insertCategory('Chain-F', e.id, userId: userId);
  }
}
