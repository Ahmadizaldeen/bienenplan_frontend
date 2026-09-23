import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'user_model.dart';

abstract class UserRepositoryContract {
  Future<AppUser> fetchCurrentUser();

  /// Lädt ein bereits validiertes Profilbild als Multipart-Datei hoch.
  Future<AppUser> uploadProfilePicture(Uint8List bytes, String filename);
}

class UserRepository implements UserRepositoryContract {
  UserRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<AppUser> fetchCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    if (response is Map<String, dynamic>) {
      return AppUser.fromJson(response);
    }
    throw Exception('Ungültiges Datenformat von API empfangen.');
  }

  @override
  Future<AppUser> uploadProfilePicture(Uint8List bytes, String filename) async {
    // Das Feld "file" ist Teil des Vertrags mit POST /api/me/picture.
    final response = await _apiClient.postMultipart(
      ApiEndpoints.uploadProfilePicture,
      'file',
      bytes,
      filename,
    );
    // Das Backend liefert den aktualisierten Benutzer, damit kein zweiter
    // GET-Aufruf notwendig ist und die Oberfläche sofort das neue Bild zeigt.
    final user = response is Map<String, dynamic> ? response['user'] : null;
    if (user is Map<String, dynamic>) {
      return AppUser.fromJson(user);
    }
    throw Exception('Ungültiges Datenformat von API empfangen.');
  }
}
