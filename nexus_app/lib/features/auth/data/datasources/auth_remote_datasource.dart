import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> login({required String username, required String password});
  Future<void> logout();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient apiClient;
  final SecureStorage secureStorage;

  AuthRemoteDatasourceImpl({
    required this.apiClient,
    required this.secureStorage,
  });

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );

      final token = response.data['token'] as String?;
      if (token == null) {
        throw const ServerException(message: 'Invalid response from server');
      }

      await secureStorage.saveToken(token);

      return UserModel(
        id: 0,
        username: username,
        email: '',
        token: token,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await secureStorage.deleteToken();
  }
}