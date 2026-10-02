import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'task_attachment.dart';

class TaskAttachmentRepository {
  TaskAttachmentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<TaskAttachment>> list(int taskId) async {
    final result = await _apiClient.get(ApiEndpoints.taskAttachments(taskId));
    if (result is! List) throw FormatException('Ungültige Anhangsliste.');
    return result
        .map((item) => TaskAttachment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TaskAttachment>> upload(
    int taskId,
    List<({String name, Uint8List bytes})> files,
  ) async {
    final result = await _apiClient.postMultipartFiles(
      ApiEndpoints.taskAttachments(taskId),
      files,
    );
    if (result is! Map<String, dynamic> || result['attachments'] is! List) {
      throw FormatException('Ungültige Upload-Antwort.');
    }
    return (result['attachments'] as List)
        .map((item) => TaskAttachment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Uint8List> download(int taskId, int attachmentId) =>
      _apiClient.getBytes(ApiEndpoints.taskAttachmentDownload(taskId, attachmentId));

  Future<void> delete(int taskId, int attachmentId) async {
    await _apiClient.delete(ApiEndpoints.taskAttachment(taskId, attachmentId));
  }
}
