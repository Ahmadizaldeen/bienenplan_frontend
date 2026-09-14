import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'project_model.dart';

abstract class ProjectRepositoryContract {
  Future<List<Project>> fetchProjects();
}

class ProjectRepository implements ProjectRepositoryContract {
  ProjectRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Project>> fetchProjects() async {
    final response = await _apiClient.get(ApiEndpoints.projects);

    if (response is List) {
      return response
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Ungültiges Datenformat von API empfangen.');
    }
  }
}
