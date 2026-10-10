import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../tasks/data/container_model.dart' as model;
import '../../tasks/data/task_model.dart';
import 'project_model.dart';

class ArchivedProjectContents {
  const ArchivedProjectContents({
    required this.containers,
    required this.tasks,
  });

  final List<model.Container> containers;
  final List<Task> tasks;
}

class ProjectArchiveRepository {
  ProjectArchiveRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  List<Map<String, dynamic>> _items(dynamic response) {
    if (response is! List) {
      throw const FormatException('Ungültige Archiv-Antwort.');
    }
    return response.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<List<Project>> fetchArchivedProjects() async =>
      _items(await _apiClient.get(ApiEndpoints.archivedProjects))
          .map(Project.fromJson)
          .toList();

  Future<void> restore(int projectId) async {
    await _apiClient.post(ApiEndpoints.restoreProject(projectId), {});
  }

  Future<ArchivedProjectContents> fetchContents(int projectId) async {
    // Der explizite Filter erlaubt dem Backend den gezielten Admin-Archivzugriff;
    // ungefilterte Listen enthalten nur aktive Projekte.
    final results = await Future.wait([
      _apiClient.get('${ApiEndpoints.containers}?project_id=$projectId'),
      _apiClient.get('${ApiEndpoints.tasks}?project_id=$projectId'),
    ]);
    return ArchivedProjectContents(
      containers: _items(results[0]).map(model.Container.fromJson).toList(),
      tasks: _items(results[1]).map(Task.fromJson).toList(),
    );
  }
}
