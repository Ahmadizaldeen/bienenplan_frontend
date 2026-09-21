import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // getter statt static const
  static String get baseUrl => "${getBaseUrl()}/BienenPlan/backend/public/api";
  static String get serverBaseUrl =>
      "${getBaseUrl()}/BienenPlan/backend/public";

  static String get login => "$baseUrl/login";
  static String get register => "$baseUrl/register";
  static String get me => "$baseUrl/me";
  static String get uploadProfilePicture => "$baseUrl/me/picture";
  static String get tasks => "$baseUrl/tasks";
  static String get projects => "$baseUrl/projects";
  static String get containers => "$baseUrl/containers";
  static String get groups => "$baseUrl/groups";

  static String taskDetail(int id) => "$baseUrl/tasks/$id";
  static String updateTaskStatus(int id) => "$baseUrl/tasks/$id/status";
  static String uploadTaskAttachment(int id) => "$baseUrl/tasks/$id/attachment";
  static String groupsForTask(int taskId) => "$baseUrl/tasks/$taskId/groups";
  static String assignGroup(int taskId, int groupId) =>
      "$baseUrl/tasks/$taskId/assign/$groupId";
  static String removeGroup(int taskId, int groupId) =>
      "$baseUrl/tasks/$taskId/groups/$groupId";

  /// Ergänzt bei relativen Upload-Pfaden die Backend-URL und bewahrt bereits
  /// vollständige URLs, die in älteren Benutzerdaten vorkommen können.
  static String attachmentUrl(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;
    return "$serverBaseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}";
  }
}

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost'; // Für Chrome / Web
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://172.23.240.1';
    case TargetPlatform.iOS:
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return 'http://localhost';
  }
}
