import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../user/data/user_model.dart';
import 'group_model.dart';

abstract class GroupRepositoryContract {
  Future<List<Group>> fetchAllGroups();
  Future<List<Group>> fetchGroupsForTask(int taskId);
  Future<List<GroupUser>> fetchAllUsers();
  Future<Group> createGroup(String name, {List<int> userIds = const []});
  Future<void> assignGroupToTask(int taskId, int groupId);
  Future<void> removeGroupFromTask(int taskId, int groupId);
}

class GroupRepository implements GroupRepositoryContract {
  GroupRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  // Die Benutzernamen persönlicher Gruppen liefert das Backend direkt als
  // personal_user_name mit (JOIN) – kein Zusatz-Request/Cache pro Gruppe mehr.
  @override
  Future<List<Group>> fetchAllGroups() async {
    final response = await _apiClient.get(ApiEndpoints.groups);
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
  Future<List<GroupUser>> fetchAllUsers() async {
    final response = await _apiClient.get(ApiEndpoints.users);
    final users = response is Map<String, dynamic>
        ? response['users']
        : response;

    if (users is List) {
      return users
          .whereType<Map<String, dynamic>>()
          .map(GroupUser.fromJson)
          .toList();
    }

    throw Exception('Ungültiges Datenformat von API empfangen.');
  }

  @override
  Future<Group> createGroup(String name, {List<int> userIds = const []}) async {
    final response = await _apiClient.post(ApiEndpoints.groups, {
      'name': name,
      'user_ids': userIds,
    });
    if (response is Map<String, dynamic> &&
        response['id'] != null &&
        response['name'] != null) {
      return Group.fromJson(response);
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
