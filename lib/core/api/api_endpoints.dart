class ApiEndpoints {
  static const String baseUrl =
      "http://localhost/BienenPlan/backend/public/api";
  static const String login = "$baseUrl/login";
  static const String register = "$baseUrl/register";
  static const String tasks = "$baseUrl/tasks";

  static String taskDetail(int id) => "$baseUrl/tasks/$id";
  static String updateTaskStatus(int id) => "$baseUrl/tasks/$id/status";
}
