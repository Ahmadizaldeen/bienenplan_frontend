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
  static String _extractErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      // Priorisierte Felder in der Reihenfolge: message > error > errors
      if (json['message'] != null) {
        return json['message'].toString();
      }
      if (json['error'] != null) {
        return json['error'].toString();
      }
      if (json['errors'] != null && json['errors'] is Map) {
        // Mehrere Fehler kombinieren
        final errors = json['errors'] as Map<String, dynamic>;
        return errors.values.map((e) => e.toString()).join(', ');
      }
    } catch (_) {
      // Fallback wenn JSON-Parse fehlschlägt
    }
    return 'Registrierung fehlgeschlagen. Bitte versuche es später erneut.';
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
      // 401 bedeutet beim Login: Die Zugangsdaten wurden abgelehnt.
      // Andere API-Fehler werden an die UI weitergegeben.
      if (error.statusCode == 401) return false;
      rethrow;
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
      // 409 = Email existiert bereits, 422 = Validierungsfehler
      if (error.statusCode == 409 || error.statusCode == 422) {
        // Extrahiere detaillierte Error-Message aus Backend-Response
        final detailedMessage = _extractErrorMessage(
          error.responseBody ?? '{}',
        );
        throw ApiException(
          statusCode: error.statusCode,
          message: detailedMessage,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.deleteToken();
  }
}
