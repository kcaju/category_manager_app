import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({
    required this.authRepository,
    UserProfile? initialUser,
  }) : super(initialUser != null ? Authenticated(initialUser) : AuthInitial());

  Future<void> checkSession() async {
    // If already authenticated from pre-loaded session, skip redundant loading
    if (state is Authenticated) return;

    emit(const AuthLoading(message: 'Checking active session...'));
    try {
      final activeUser = await authRepository.getActiveSession();
      if (activeUser != null) {
        emit(Authenticated(activeUser));
      } else {
        await loadAvailableUsers();
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> loadAvailableUsers() async {
    emit(const AuthLoading(message: 'Loading users from JSONPlaceholder API...'));
    try {
      final users = await authRepository.fetchAvailableUsers();
      emit(Unauthenticated(availableUsers: users));
    } catch (e) {
      emit(AuthError('Failed to fetch users: ${e.toString()}'));
    }
  }

  Future<void> loginWithUser(UserProfile user) async {
    emit(const AuthLoading(message: 'Logging in...'));
    try {
      await authRepository.saveSession(user);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> loginWithUserId(int userId) async {
    emit(const AuthLoading(message: 'Fetching user details...'));
    try {
      final user = await authRepository.loginWithUserId(userId);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('User not found or network error: ${e.toString()}'));
    }
  }

  Future<void> loginWithIdentifier(String identifier) async {
    emit(const AuthLoading(message: 'Authenticating with API...'));
    try {
      final trimmed = identifier.trim().toLowerCase();

      // Check if user entered a numeric ID
      final numericId = int.tryParse(trimmed);
      if (numericId != null) {
        final user = await authRepository.loginWithUserId(numericId);
        emit(Authenticated(user));
        return;
      }

      // Fetch users from API to match email or username
      final users = await authRepository.fetchAvailableUsers();
      final matched = users.where((u) =>
          u.email.toLowerCase() == trimmed ||
          u.username.toLowerCase() == trimmed).firstOrNull;

      if (matched != null) {
        await authRepository.saveSession(matched);
        emit(Authenticated(matched));
      } else if (users.isNotEmpty) {
        // If email not found in mock JSONPlaceholder set, log in with first available user
        final defaultUser = users.first;
        await authRepository.saveSession(defaultUser);
        emit(Authenticated(defaultUser));
      } else {
        emit(const AuthError('No users available from JSONPlaceholder API.'));
      }
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading(message: 'Logging out...'));
    try {
      await authRepository.logout();
      await loadAvailableUsers();
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }
}

