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

      if (response != null && response['token'] != null) {
        await _apiClient.saveToken(response['token']);
        return true;
      }
      return false;
    } on ApiException catch (error) {
      // 409 = Email existiert bereits, 422 = Validierungsfehler
      if (error.statusCode == 409 || error.statusCode == 422) {
        // Versuche, detaillierte Error-Message aus Backend zu extrahieren
        try {
          // Backend sollte JSON mit "message" oder "error" Feld zurückgeben
          // Momentan schlucken wir nur und geben false zurück
          // TODO: Parser erweitern für bessere Error-Messages
          return false;
        } catch (e) {
          return false;
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.deleteToken();
  }
}
