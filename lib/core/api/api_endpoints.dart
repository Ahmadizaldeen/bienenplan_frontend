import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Optionaler Build-Parameter: Backend-Basisadresse ohne /api am Ende.
  // Beispiel: http://192.168.1.25/BienenPlanBackend/backend/public
  static const _configuredServerBaseUrl = String.fromEnvironment(
    'API_SERVER_BASE_URL',
  );

  // Gemeinsamer Präfix aller API-Routen. GET auf /api liefert den API-Status.
  static String get baseUrl => '$serverBaseUrl/api';

  // Verwendet den Build-Parameter oder setzt eine plattformspezifische
  // Adresse mit dem XAMPP-Projektpfad zusammen.
  static String get serverBaseUrl => _configuredServerBaseUrl.isNotEmpty
      ? _configuredServerBaseUrl.replaceFirst(RegExp(r'/+$'), '')
      : '${getBaseUrl()}/BienenPlanBackend/backend/public';

  // Öffentliche Authentifizierungs-Routen.
  static String get login => "$baseUrl/login";
  static String get register => "$baseUrl/register";

  // Benutzer-Routen (außer Login und Registrierung authentifizierungspflichtig).
  static String get me => "$baseUrl/me";
  static String get users => "$baseUrl/users";
  static String get uploadProfilePicture => "$baseUrl/me/picture";

  // Aufgaben-Routen.
  static String get tasks => "$baseUrl/tasks";
  // GET ruft eine Aufgabe ab, PUT aktualisiert sie, DELETE entfernt sie.
  static String taskDetail(int id) => "$baseUrl/tasks/$id";

  static String subtasks(int taskId) => "${taskDetail(taskId)}/subtasks";
  static String subtask(int taskId, int subtaskId) =>
      "${subtasks(taskId)}/$subtaskId";

  // POST setzt den Status; der neue Status wird im Request-Body übergeben.
  static String updateTaskStatus(int id) => "$baseUrl/tasks/$id/status";

  // Ältere Route zum Hochladen eines einzelnen Aufgaben-Anhangs.
  static String uploadTaskAttachment(int id) => "$baseUrl/tasks/$id/attachment";

  // GET listet Anhänge; POST lädt Anhang/Anhänge hoch.
  static String taskAttachments(int id) => "$baseUrl/tasks/$id/attachments";

  // Route für einen einzelnen Anhang.
  static String taskAttachment(int id, int attachmentId) =>
      "${taskAttachments(id)}/$attachmentId";

  // GET lädt die Datei-Bytes des Anhangs herunter.
  static String taskAttachmentDownload(int id, int attachmentId) =>
      "${taskAttachment(id, attachmentId)}/download";

  // Projekt-Routen.
  static String get projects => "$baseUrl/projects";

  // Behälter-Routen.
  static String get containers => "$baseUrl/containers";

  // Gruppen-Routen und Zuordnung von Gruppen zu Aufgaben.
  static String get groups => "$baseUrl/groups";
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
    return 'https://localhost';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Adresse des Host-PCs im Android-Emulator. Für ein echtes Handy muss
      // API_SERVER_BASE_URL auf die WLAN-IP des PCs gesetzt werden.
      return 'http://172.23.240.1';
    case TargetPlatform.iOS:
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return 'https://mulled-custodian-patriot.ngrok-free.dev';
  }
}
