import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<UserProfile>> fetchAvailableUsers() async {
    return await remoteDataSource.fetchUsers();
  }

  @override
  Future<UserProfile> loginWithUserId(int userId) async {
    final user = await remoteDataSource.fetchUserById(userId);
    await localDataSource.saveSession(user);
    return user;
  }

  @override
  Future<UserProfile?> getActiveSession() async {
    return await localDataSource.getActiveSession();
  }

  @override
  Future<void> saveSession(UserProfile user) async {
    final userModel = UserModel(
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      phone: user.phone,
      website: user.website,
      companyName: user.companyName,
      companyCatchPhrase: user.companyCatchPhrase,
      companyBs: user.companyBs,
      street: user.street,
      suite: user.suite,
      city: user.city,
      zipcode: user.zipcode,
    );
    await localDataSource.saveSession(userModel);
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }
}

