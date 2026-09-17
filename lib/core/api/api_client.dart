import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();

  // JWT Token speichern
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // JWT Token lesen
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // JWT Token löschen (Logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Generic GET Request mit Bearer Token Header
  Future<dynamic> get(String url) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  // Generic POST Request
  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // Generic PUT Request
  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // Generic DELETE Request
  Future<dynamic> delete(String url) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  // Multipart POST Request (z.B. für Datei-Uploads)
  Future<dynamic> postMultipart(
    String url,
    String fieldName,
    Uint8List bytes,
    String filename,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // Response Handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      deleteToken(); // Token löschen, wenn nicht autorisiert
      throw ApiException(
        statusCode: 401,
        message: 'Nicht autorisiert.',
        responseBody: response.body,
      );
    } else {
      String errorMessage = 'API Fehler [${response.statusCode}]';
      try {
        if (response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['message'] != null &&
                decoded['message'].toString().isNotEmpty) {
              errorMessage = decoded['message'].toString();
            } else if (decoded['error'] != null &&
                decoded['error'].toString().isNotEmpty) {
              errorMessage = decoded['error'].toString();
            }
          }
        }
      } catch (_) {
        // Fallback auf Standardmeldung, wenn kein valides JSON vorhanden ist
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        responseBody: response.body, // Speichere den rohen Body
      );
    }
  }
}
