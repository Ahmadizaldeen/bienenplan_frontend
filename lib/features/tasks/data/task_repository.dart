import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'task_model.dart';

class TaskRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Task>> fetchTasks() async {
    final response = await _apiClient.get(ApiEndpoints.tasks);

    if (response is List) {
      return response.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Ungültiges Datenformat von API empfangen.');
    }
  }

  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    await _apiClient.post(
      ApiEndpoints.updateTaskStatus(taskId),
      {'status': newStatus},
    );
  }
}
