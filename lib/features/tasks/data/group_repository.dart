import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'group_model.dart';

abstract class GroupRepositoryContract {
  /// Liefert die Gruppen, die in diesem Projekt Aufgaben zugeordnet werden können.
  Future<List<Group>> fetchGroupsForProject(int projectId);

  /// Lädt die einer Aufgabe zugeordneten Gruppen für ihre Detailansicht.
  Future<List<Group>> fetchGroupsForTask(int taskId);

  /// Fügt eine Gruppenzuordnung hinzu; die Aufgabe selbst bleibt unverändert.
  Future<void> assignGroupToTask(int taskId, int groupId);

  /// Entfernt nur die Zuordnung zwischen Aufgabe und Gruppe.
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

  // Beide Endpoints können Gruppen direkt oder innerhalb eines "groups"-Felds
  // zurückgeben. Einheitliches Parsing und Sortieren hält die Anzeige stabil.
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
    // Der Endpoint erwartet keine Nutzdaten; Aufgabe und Gruppe stehen in der URL.
    await _apiClient.post(ApiEndpoints.assignGroup(taskId, groupId), {});
  }

  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {
    await _apiClient.delete(ApiEndpoints.removeGroup(taskId, groupId));
  }
}
