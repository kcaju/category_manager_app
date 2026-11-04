import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<List<UserModel>> fetchUsers();
  Future<UserModel> fetchUserById(int id);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<UserModel>> fetchUsers() async {
    final response = await apiClient.get<List<dynamic>>(AppConstants.usersEndpoint);
    if (response.data != null) {
      return (response.data!)
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<UserModel> fetchUserById(int id) async {
    final response = await apiClient.get<Map<String, dynamic>>('${AppConstants.usersEndpoint}/$id');
    if (response.data != null) {
      return UserModel.fromJson(response.data!);
    }
    throw Exception('User $id not found');
  }
}

