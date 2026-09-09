// Eine API-Exception enthält neben dem Fehlertext auch den HTTP-Status.
// So kann die Anwendung auf Statuscodes reagieren, ohne Texte zu vergleichen.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
