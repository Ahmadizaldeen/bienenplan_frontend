import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';

abstract class AuthRepositoryContract {
  Future<bool> login(String email, String password);
  Future<bool> register(String name, String email, String password);
  Future<void> logout();
}

class AuthRepository implements AuthRepositoryContract {
  final ApiClient _apiClient = ApiClient();

  /// Versucht, eine detaillierte Error-Message aus dem Backend-Response zu extrahieren.
  /// Backend kann JSON zurückgeben wie: {"message": "...", "error": "...", "errors": {...}}
  static String _extractErrorMessage(
    String? responseBody, {
    required String fallbackMessage,
  }) {
    if (responseBody != null && responseBody.isNotEmpty) {
      try {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        // Priorisierte Felder in der Reihenfolge: message > error > errors
        if (json['message'] != null && json['message'].toString().isNotEmpty) {
          return json['message'].toString();
        }
        if (json['error'] != null && json['error'].toString().isNotEmpty) {
          return json['error'].toString();
        }
        if (json['errors'] != null && json['errors'] is Map) {
          // Mehrere Fehler kombinieren
          final errors = json['errors'] as Map<String, dynamic>;
          final messages = errors.values
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty);
          if (messages.isNotEmpty) {
            return messages.join(', ');
          }
        }
      } catch (_) {
        // Fallback wenn JSON-Parse fehlschlägt
      }
    }
    return fallbackMessage;
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.login, {
        'email': email,
        'password': password,
      });

      if (response != null && response['token'] != null) {
        await _apiClient.saveToken(response['token']);
        return true;
      }
      return false;
    } on ApiException catch (error) {
      final detailedMessage = _extractErrorMessage(
        error.responseBody,
        fallbackMessage: 'Anmeldung fehlgeschlagen. Ungültige Zugangsdaten.',
      );
      throw ApiException(
        statusCode: error.statusCode,
        message: detailedMessage,
        responseBody: error.responseBody,
      );
    }
  }

  @override
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.register, {
        'name': name,
        'email': email,
        'password': password,
      });

      // Wenn die API erfolgreich antwortet (2xx), ist die Registrierung OK
      // Manche APIs geben kein Token zurück, nur beim Login
      if (response != null && response['token'] != null) {
        await _apiClient.saveToken(response['token']);
        return true;
      }

      // Wenn kein Token, aber Response OK (2xx) -> trotzdem Erfolg
      // User wurde registriert, aber muss sich anmelden
      if (response != null) {
        return true;
      }

      return false;
    } on ApiException catch (error) {
      final detailedMessage = _extractErrorMessage(
        error.responseBody,
        fallbackMessage:
            'Registrierung fehlgeschlagen. Bitte versuche es später erneut.',
      );
      throw ApiException(
        statusCode: error.statusCode,
        message: detailedMessage,
        responseBody: error.responseBody,
      );
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.deleteToken();
  }
}
