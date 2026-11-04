import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final defaultDatabasesPath = await getDatabasesPath();
    final dbPath = p.join(defaultDatabasesPath, AppConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppConstants.categoriesTable} ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute('DROP INDEX IF EXISTS idx_category_parent_name');
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_category_user_parent_name
        ON ${AppConstants.categoriesTable} (user_id, IFNULL(parent_id, 0), LOWER(name))
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_category_user_id
        ON ${AppConstants.categoriesTable} (user_id)
      ''');
    }

    if (oldVersion < 3) {
      await db.delete(AppConstants.categoriesTable);
      try {
        await db.delete(
          'sqlite_sequence',
          where: 'name = ?',
          whereArgs: [AppConstants.categoriesTable],
        );
      } catch (_) {}
    }

    if (oldVersion < 4) {
      // Recreate categories table to support user-scoped sequential IDs starting from 1
      await db.execute('DROP TABLE IF EXISTS ${AppConstants.categoriesTable}');
      await _createCategoriesTable(db);
    }
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.categoriesTable} (
        db_id INTEGER PRIMARY KEY AUTOINCREMENT,
        id INTEGER NOT NULL,
        user_id INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        parent_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // Unique category ID per user (so each user's categories start from 1, 2, 3...)
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_category_user_id_unique
      ON ${AppConstants.categoriesTable} (user_id, id)
    ''');

    // Case-insensitive unique index on (user_id, parent_id, name)
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_category_user_parent_name
      ON ${AppConstants.categoriesTable} (user_id, IFNULL(parent_id, 0), LOWER(name))
    ''');

    // Index on user_id for fast isolation
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_category_user_id
      ON ${AppConstants.categoriesTable} (user_id)
    ''');

    // Index on (user_id, parent_id) for fast tree traversal and child lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_category_user_parent_id
      ON ${AppConstants.categoriesTable} (user_id, parent_id)
    ''');

    // Index on (user_id, name) for fast search
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_category_user_name
      ON ${AppConstants.categoriesTable} (user_id, name)
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCategoriesTable(db);

    // User session table for persisting authenticated user
    await db.execute('''
      CREATE TABLE ${AppConstants.sessionTable} (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        website TEXT NOT NULL,
        company_name TEXT NOT NULL,
        raw_json TEXT NOT NULL,
        logged_in_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
