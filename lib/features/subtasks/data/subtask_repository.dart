import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import 'subtask_model.dart';

abstract class SubtaskRepositoryContract {
  Future<SubtaskList> list(int taskId);
  Future<Subtask> create(int taskId, String title);
  Future<Subtask> update(int taskId, int id, {String? title, bool? completed});
  Future<void> delete(int taskId, int id);
}

class SubtaskRepository implements SubtaskRepositoryContract {
  SubtaskRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Subtask _item(dynamic data) {
    try {
      return Subtask.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException(
        statusCode: 502,
        message: 'Ungueltige Teilaufgabe vom Server.',
      );
    }
  }

  @override
  Future<SubtaskList> list(int taskId) async {
    final data = await _apiClient.get(ApiEndpoints.subtasks(taskId));
    if (data is! Map<String, dynamic> ||
        data['subtasks'] is! List ||
        data['can_create'] is! bool) {
      throw const ApiException(
        statusCode: 502,
        message: 'Ungueltige Teilaufgabenliste vom Server.',
      );
    }
    return SubtaskList(
      items: (data['subtasks'] as List).map(_item).toList(),
      canCreate: data['can_create'] as bool,
    );
  }

  @override
  Future<Subtask> create(int taskId, String title) async => _item(
    await _apiClient.post(ApiEndpoints.subtasks(taskId), {
      'title': title.trim(),
    }),
  );

  @override
  Future<Subtask> update(
    int taskId,
    int id, {
    String? title,
    bool? completed,
  }) async => _item(
    await _apiClient.put(ApiEndpoints.subtask(taskId, id), {
      // Partial updates keep title edits separate from checkbox permissions.
      if (title != null) 'title': title.trim(),
      'completed': ?completed,
    }),
  );

  @override
  Future<void> delete(int taskId, int id) async {
    await _apiClient.delete(ApiEndpoints.subtask(taskId, id));
  }
}
