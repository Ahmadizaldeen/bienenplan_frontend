import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'group_model.dart';

abstract class GroupRepositoryContract {
  Future<List<Group>> fetchGroupsForProject(int projectId);
  Future<List<Group>> fetchGroupsForTask(int taskId);
  Future<void> assignGroupToTask(int taskId, int groupId);
  Future<void> removeGroupFromTask(int taskId, int groupId);
}

class GroupRepository implements GroupRepositoryContract {
  GroupRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Group>> fetchGroupsForProject(int projectId) async {
    // Nur dem Projekt zugeordnete Gruppen sind im Aufgabendialog auswählbar.
    final response = await _apiClient.get(
      ApiEndpoints.groupsForProject(projectId),
    );
    return _parseGroups(response);
  }

  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async {
    final response = await _apiClient.get(ApiEndpoints.groupsForTask(taskId));
    return _parseGroups(response);
  }

  // Gemeinsames Parsing für beide Gruppen-Endpoints; sortiert nach Anzeigename,
  // da das Backend nach dem technischen Namen ("Personal user {id}") sortiert.
  List<Group> _parseGroups(dynamic response) {
    final groups = response is Map<String, dynamic>
        ? response['groups']
        : response;

    if (groups is List) {
      return groups
          .whereType<Map<String, dynamic>>()
          .map(Group.fromJson)
          .toList()
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
    }

    throw Exception('Ungültiges Datenformat von API empfangen.');
  }

  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {
    await _apiClient.post(ApiEndpoints.assignGroup(taskId, groupId), {});
  }

  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {
    await _apiClient.delete(ApiEndpoints.removeGroup(taskId, groupId));
  }
}
