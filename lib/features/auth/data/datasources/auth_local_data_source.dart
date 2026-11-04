import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getActiveSession();
  Future<void> saveSession(UserModel user);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final AppDatabase databaseHelper;

  AuthLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<UserModel?> getActiveSession() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      AppConstants.sessionTable,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return UserModel.fromDbMap(results.first);
    }
    return null;
  }

  @override
  Future<void> saveSession(UserModel user) async {
    final db = await databaseHelper.database;
    await db.insert(
      AppConstants.sessionTable,
      user.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearSession() async {
    final db = await databaseHelper.database;
    await db.delete(AppConstants.sessionTable);
  }
}

