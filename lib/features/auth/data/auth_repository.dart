import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';

abstract class AuthRepositoryContract {
  Future<bool> login(String email, String password);
  Future<void> logout();
}

class AuthRepository implements AuthRepositoryContract {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.login, {
        'email': email,
        'password': password,
      });

      if (response != null && response['token'] != null) {
        await _apiClient.saveToken(response['token']);
        return true;
      }
      return false;
    } on ApiException catch (error) {
      // 401 bedeutet beim Login: Die Zugangsdaten wurden abgelehnt.
      // Andere API-Fehler werden an die UI weitergegeben.
      if (error.statusCode == 401) return false;
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.deleteToken();
  }
}
