import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/models/user_profile.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/category/data/datasources/category_local_data_source.dart';
import 'features/category/data/repositories/category_repository_impl.dart';
import 'features/category/presentation/cubit/category_cubit.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final apiClient = ApiClient();
  final databaseHelper = AppDatabase.instance;

  // Initialize Data Sources
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final authLocalDataSource = AuthLocalDataSourceImpl(databaseHelper: databaseHelper);
  final categoryLocalDataSource = CategoryLocalDataSourceImpl(databaseHelper: databaseHelper);

  // Initialize Repositories
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );
  final categoryRepository = CategoryRepositoryImpl(
    localDataSource: categoryLocalDataSource,
  );

  // Pre-load active session from SQLite before runApp so there is ZERO flash of LoginScreen
  final initialUser = await authRepository.getActiveSession();

  runApp(
    MyApp(
      authRepository: authRepository,
      categoryRepository: categoryRepository,
      initialUser: initialUser,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final CategoryRepositoryImpl categoryRepository;
  final UserProfile? initialUser;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.categoryRepository,
    this.initialUser,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) {
            final cubit = AuthCubit(
              authRepository: authRepository,
              initialUser: initialUser,
            );
            if (initialUser == null) {
              cubit.loadAvailableUsers();
            }
            return cubit;
          },
        ),
        BlocProvider<CategoryCubit>(
          create: (_) => CategoryCubit(categoryRepository: categoryRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Category Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return MainNavigationScreen(user: state.user);
        }
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFF08080B),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
              ),
            ),
          );
        }
        return const LoginScreen();
      },
    );
  }
}
