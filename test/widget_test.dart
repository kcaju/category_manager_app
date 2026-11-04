import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:category_manager_app/core/theme/app_theme.dart';
import 'package:category_manager_app/features/auth/domain/models/user_profile.dart';
import 'package:category_manager_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:category_manager_app/features/category/domain/repositories/category_repository.dart';
import 'package:category_manager_app/features/category/domain/models/category_item.dart';
import 'package:category_manager_app/features/category/domain/models/category_tree_node.dart';
import 'package:category_manager_app/features/category/domain/models/category_search_result.dart';
import 'package:category_manager_app/features/category/domain/models/paginated_result.dart';
import 'package:category_manager_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:category_manager_app/features/category/presentation/cubit/category_cubit.dart';
import 'package:category_manager_app/features/auth/presentation/screens/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<List<UserProfile>> fetchAvailableUsers() async => [];

  @override
  Future<UserProfile?> getActiveSession() async => null;

  @override
  Future<UserProfile> loginWithUserId(int userId) async {
    return const UserProfile(
      id: 1,
      name: 'Leanne Graham',
      username: 'Bret',
      email: 'Sincere@april.biz',
      phone: '1-770-736-8031 x56442',
      website: 'hildegard.org',
      companyName: 'Romaguera-Crona',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> saveSession(UserProfile user) async {}
}

class FakeCategoryRepository implements CategoryRepository {
  @override
  Future<void> clearAllCategories({int? userId}) async {}

  @override
  Future<CategoryItem> createCategory({required String name, int? parentId, int? userId}) async {
    return CategoryItem(id: 1, name: name, parentId: parentId, createdAt: DateTime.now());
  }

  @override
  Future<void> deleteCategory(int id, {int? userId}) async {}

  @override
  Future<List<CategoryItem>> getAllCategoriesFlat({int? userId}) async => [];

  @override
  Future<CategorySearchResult> getCategoryDetails(int id, {int? userId}) async {
    return CategorySearchResult(
      category: CategoryItem(id: 1, name: 'Root', createdAt: DateTime.now()),
    );
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree({int? userId}) async => [];

  @override
  Future<PaginatedResult<CategorySearchResult>> searchCategories({
    required String query,
    int? limit,
    int page = 1,
    int pageSize = 20,
    int? userId,
  }) async {
    return const PaginatedResult(page: 1, pageSize: 20, totalCount: 0, items: []);
  }

  @override
  Future<void> seedDefaultCategories({int? userId}) async {}
}

void main() {
  testWidgets('App smoke test: loads login screen with Lumora title and heading', (WidgetTester tester) async {
    final authRepo = FakeAuthRepository();
    final categoryRepo = FakeCategoryRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(authRepository: authRepo),
          ),
          BlocProvider<CategoryCubit>(
            create: (_) => CategoryCubit(categoryRepository: categoryRepo),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Lumora'), findsOneWidget);
    expect(find.text('Log In, Manage Your\nCategories'), findsOneWidget);
    expect(find.text('SELECT USER ID'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
