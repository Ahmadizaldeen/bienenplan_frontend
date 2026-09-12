// Eine API-Exception enthält neben dem Fehlertext auch den HTTP-Status.
// So kann die Anwendung auf Statuscodes reagieren, ohne Texte zu vergleichen.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.responseBody,
  });

  final int statusCode;
  final String message;
  final String? responseBody; // Roher Backend-Response für besseres Parsing

  @override
  String toString() => message;
}
