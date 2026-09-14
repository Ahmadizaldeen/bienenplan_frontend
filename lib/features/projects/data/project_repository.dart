import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'project_model.dart';

abstract class ProjectRepositoryContract {
  Future<List<Project>> fetchProjects();
}

class ProjectRepository implements ProjectRepositoryContract {
  ProjectRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  // ignore: unused_field
  // Bereits vorbereitet für den echten API-Call (siehe TODO in fetchProjects()).
  final ApiClient _apiClient;

  static const List<Project> _placeholderProjects = [
    Project(id: 1, name: 'BienenPlan', isActive: true),
    Project(id: 2, name: 'Marketing'),
    Project(id: 3, name: 'Ressourcen'),
  ];
 
  @override
  Future<List<Project>> fetchProjects() async {
    // MOCK: Backend-Endpunkt GET /projects existiert noch nicht (siehe ApiEndpoints).
    // TODO: Sobald der Endpunkt steht, ersetzen durch:
    //   final response = await _apiClient.get(ApiEndpoints.projects);
    //   if (response is List) {
    //     return response.map((json) => Project.fromJson(json)).toList();
    //   }
    //   throw Exception('Ungültiges Datenformat von API empfangen.');
    return _placeholderProjects;
  }
}