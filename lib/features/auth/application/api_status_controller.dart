import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class ApiStatusController {
  ApiStatusController({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String?> checkApi() async {
    final response = await _apiClient.get(ApiEndpoints.baseUrl);
    return response?.toString();
  }
}
