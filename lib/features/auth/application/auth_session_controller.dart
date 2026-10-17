import '../../../core/api/api_client.dart';

class AuthSessionController {
  AuthSessionController({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String?> getToken() => _apiClient.getToken();
}
