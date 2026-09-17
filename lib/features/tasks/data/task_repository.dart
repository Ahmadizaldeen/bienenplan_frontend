import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'task_model.dart';

abstract class TaskRepositoryContract {
  Future<List<Task>> fetchTasks();
  Future<Task> fetchTaskDetail(int taskId);
  Future<void> updateTaskStatus(int taskId, String newStatus);
  Future<void> updateTask(
    int taskId, {
    required String title,
    String description,
    String status,
    String? deadline,
    String? attachment,
  });
  Future<String> uploadAttachment(int taskId, Uint8List bytes, String filename);
  Future<int> createTask({
    required int containerId,
    required String title,
    String description,
    String status,
    String? deadline,
    String? attachment,
  });
}

class TaskRepository implements TaskRepositoryContract {
  TaskRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Task>> fetchTasks() async {
    final response = await _apiClient.get(ApiEndpoints.tasks);
    final tasks = response is Map<String, dynamic>
        ? response['data']
        : response;

    if (tasks is List) {
      return tasks
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    }

    throw Exception('Ungültiges Datenformat von API empfangen.');
  }

  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    await _apiClient.post(ApiEndpoints.updateTaskStatus(taskId), {
      'status': newStatus,
    });
  }

  @override
  Future<Task> fetchTaskDetail(int taskId) async {
    final response = await _apiClient.get(ApiEndpoints.taskDetail(taskId));
    if (response is Map<String, dynamic>) {
      return Task.fromJson(response);
    }
    throw Exception('Ungültiges Datenformat von API empfangen.');
  }

  @override
  Future<void> updateTask(
    int taskId, {
    required String title,
    String description = '',
    String status = 'pending',
    String? deadline,
    String? attachment,
  }) async {
    await _apiClient.put(ApiEndpoints.taskDetail(taskId), {
      'title': title,
      'description': description,
      'status': status,
      'deadline': ?deadline,
      'attachment': ?attachment,
    });
  }

  @override
  Future<String> uploadAttachment(
    int taskId,
    Uint8List bytes,
    String filename,
  ) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.uploadTaskAttachment(taskId),
      'file',
      bytes,
      filename,
    );

    if (response is Map<String, dynamic> && response['attachment'] != null) {
      return response['attachment'].toString();
    }
    throw Exception('Ungültiges Datenformat von API empfangen.');
  }

  @override
  Future<int> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'pending',
    String? deadline,
    String? attachment,
  }) async {
    // created_by wird vom Backend anhand des JWT ermittelt.
    // Die Antwort wird bewusst nicht geparst, da ihr Format vom
    // GET /tasks-Format abweichen kann; die Liste wird danach neu geladen.
    final response = await _apiClient.post(ApiEndpoints.tasks, {
      'container_id': containerId,
      'title': title,
      'description': description,
      'status': status,
      if (deadline != null && deadline.isNotEmpty) 'deadline': deadline,
      if (attachment != null && attachment.isNotEmpty) 'attachment': attachment,
    });

    if (response is Map<String, dynamic> && response['id'] != null) {
      return response['id'] is int
          ? response['id'] as int
          : int.tryParse(response['id'].toString()) ?? 0;
    }

    throw Exception('Ungültiges Datenformat von API empfangen.');
  }
}
