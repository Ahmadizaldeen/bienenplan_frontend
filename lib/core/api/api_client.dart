import 'dart:convert';

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
      throw ApiException(
        statusCode: response.statusCode,
        message: 'API Fehler [${response.statusCode}]',
        responseBody: response.body, // Speichere den rohen Body
      );
    }
  }
}
