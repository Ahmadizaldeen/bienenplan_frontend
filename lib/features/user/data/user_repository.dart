import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'user_model.dart';

abstract class UserRepositoryContract {
  Future<AppUser> fetchCurrentUser();
}

class UserRepository implements UserRepositoryContract {
  UserRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<AppUser> fetchCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    if (response is Map<String, dynamic>) {
      return AppUser.fromJson(response);
    }
    throw Exception('Ungültiges Datenformat von API empfangen.');
  }
}
