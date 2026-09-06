import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<bool> login(String email, String password) async {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        {
          'email': email,
          'password': password,
        },
      );

      if (response != null && response['token'] != null) {
        await _apiClient.saveToken(response['token']);
        return true;
      }
      return false;
  }

  Future<void> logout() async {
    await _apiClient.deleteToken();
  }
}
