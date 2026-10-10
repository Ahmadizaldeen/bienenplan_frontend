import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'project_model.dart';
import 'project_group_model.dart';
import '../../user/data/user_model.dart';

abstract class ProjectRepositoryContract {
  Future<List<Project>> fetchProjects();
  Future<void> createProject(String name);
  Future<void> updateProject(int id, String name);
  Future<void> archiveProject(int id);
  Future<List<ProjectGroup>> fetchProjectGroups(int projectId);
  Future<List<ProjectGroup>> fetchAvailableGroups();
  Future<void> assignGroup(int projectId, int groupId);
  Future<void> removeGroup(int projectId, int groupId);
  Future<List<GroupUser>> fetchUsers();
  Future<void> createGroup(int projectId, String name, List<int> userIds);
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

  @override
  Future<void> createProject(String name) async {
    await _apiClient.post(ApiEndpoints.projects, {'name': name});
  }

  @override
  Future<void> updateProject(int id, String name) async {
    await _apiClient.put(ApiEndpoints.projectDetail(id), {'name': name});
  }

  @override
  Future<void> archiveProject(int id) async {
    // DELETE archiviert das Projekt im Backend, statt seine Inhalte zu entfernen.
    await _apiClient.delete(ApiEndpoints.projectDetail(id));
  }

  @override
  Future<List<ProjectGroup>> fetchProjectGroups(int projectId) async {
    final response = await _apiClient.get(
      ApiEndpoints.projectGroups(projectId),
    );
    return _parseGroups(response);
  }

  @override
  Future<List<ProjectGroup>> fetchAvailableGroups() async {
    final response = await _apiClient.get(ApiEndpoints.groups);
    return _parseGroups(response);
  }

  List<ProjectGroup> _parseGroups(dynamic response) {
    final groups = response is Map<String, dynamic>
        ? response['groups']
        : response;
    if (groups is! List) {
      throw Exception('Ungültiges Gruppen-Datenformat von API empfangen.');
    }
    return groups
        .whereType<Map<String, dynamic>>()
        .map(ProjectGroup.fromJson)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<void> assignGroup(int projectId, int groupId) async {
    await _apiClient.post(ApiEndpoints.projectGroup(projectId, groupId), {});
  }

  @override
  Future<void> removeGroup(int projectId, int groupId) async {
    await _apiClient.delete(ApiEndpoints.projectGroup(projectId, groupId));
  }

  @override
  Future<List<GroupUser>> fetchUsers() async {
    final response = await _apiClient.get(ApiEndpoints.users);
    final users = response is Map<String, dynamic>
        ? response['users']
        : response;
    if (users is! List) {
      throw Exception('Ungültiges Benutzer-Datenformat von API empfangen.');
    }
    return users
        .whereType<Map<String, dynamic>>()
        .map(GroupUser.fromJson)
        .toList();
  }

  @override
  Future<void> createGroup(
    int projectId,
    String name,
    List<int> userIds,
  ) async {
    await _apiClient.post(ApiEndpoints.projectGroups(projectId), {
      'name': name,
      'user_ids': userIds,
    });
  }
}
