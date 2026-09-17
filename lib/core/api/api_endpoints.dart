class ApiEndpoints {
  static const String baseUrl =
      "http://localhost/BienenPlan/backend/public/api";
  static const String serverBaseUrl =
      "http://localhost/BienenPlan/backend/public";
  static const String login = "$baseUrl/login";
  static const String register = "$baseUrl/register";
  static const String tasks = "$baseUrl/tasks";
  static const String projects = "$baseUrl/projects";
  static const String containers = "$baseUrl/containers";
  static const String groups = "$baseUrl/groups";

  static String taskDetail(int id) => "$baseUrl/tasks/$id";
  static String updateTaskStatus(int id) => "$baseUrl/tasks/$id/status";
  static String uploadTaskAttachment(int id) => "$baseUrl/tasks/$id/attachment";
  static String groupsForTask(int taskId) => "$baseUrl/tasks/$taskId/groups";
  static String assignGroup(int taskId, int groupId) =>
      "$baseUrl/tasks/$taskId/assign/$groupId";
  static String removeGroup(int taskId, int groupId) =>
      "$baseUrl/tasks/$taskId/groups/$groupId";

  /// Baut die vollständige URL zu einem gespeicherten Anhang (relativer Pfad
  /// wie z.B. "uploads/tasks/xyz.pdf") auf.
  static String attachmentUrl(String relativePath) =>
      "$serverBaseUrl/$relativePath";
}
