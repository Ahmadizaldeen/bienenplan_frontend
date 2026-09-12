import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'task_model.dart';

abstract class TaskRepositoryContract {
  Future<List<Task>> fetchTasks();
  Future<void> updateTaskStatus(int taskId, String newStatus);
}

class TaskRepository implements TaskRepositoryContract {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<Task>> fetchTasks() async {
    final response = await _apiClient.get(ApiEndpoints.tasks);

    if (response is List) {
      return response.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Ungültiges Datenformat von API empfangen.');
    }
  }

  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    await _apiClient.post(
      ApiEndpoints.updateTaskStatus(taskId),
      {'status': newStatus},
    );
  }
}
