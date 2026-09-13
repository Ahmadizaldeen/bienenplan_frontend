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

  static const List<Project> _placeholderProjects = [
    Project(id: 1, name: 'BienenPlan', isActive: true),
    Project(id: 2, name: 'Marketing'),
    Project(id: 3, name: 'Ressourcen'),
  ];

  @override
  Future<List<Project>> fetchProjects() async {
    try {

    // TODO: Implement API call to fetch projects.

      throw Exception('Ungültiges Datenformat von API empfangen.');
    } catch (_) {
      return _placeholderProjects;
    }
  }
}
