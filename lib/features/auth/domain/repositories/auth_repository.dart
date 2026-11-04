import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<List<UserProfile>> fetchAvailableUsers();
  Future<UserProfile> loginWithUserId(int userId);
  Future<UserProfile?> getActiveSession();
  Future<void> saveSession(UserProfile user);
  Future<void> logout();
}

