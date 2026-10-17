import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import 'chat_message.dart';

abstract class ChatRepositoryContract {
  Future<ChatMessage> sendMessage(int projectId, List<ChatMessage> messages);
}

class ChatRepository implements ChatRepositoryContract {
  ChatRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<ChatMessage> sendMessage(
    int projectId,
    List<ChatMessage> messages,
  ) async {
    try {
      // Das Backend wartet bis zu 180 Sekunden auf Ollama; der kleine Puffer
      // verhindert, dass der Client vor dem Backend abbricht.
      final response = await _apiClient.post(
        ApiEndpoints.projectChat(projectId),
        {'messages': messages.map((message) => message.toJson()).toList()},
        timeout: const Duration(seconds: 190),
      );
      if (response is Map<String, dynamic> &&
          response['message'] is Map<String, dynamic>) {
        final message = response['message'] as Map<String, dynamic>;
        final role = message['role'];
        final content = message['content'];
        if (role == 'assistant' &&
            content is String &&
            content.trim().isNotEmpty) {
          return ChatMessage(role: 'assistant', content: content);
        }
      }
      // Auch eine HTTP-Erfolgsantwort mit unerwartetem Format gilt als API-Fehler.
      throw const ApiException(
        statusCode: 200,
        message: 'Der Chat hat eine ungültige Antwort zurückgegeben.',
      );
    } on ApiException {
      rethrow;
    } on FormatException catch (error) {
      throw ApiException(
        statusCode: 200,
        message: 'Der Chat hat eine ungültige Antwort zurückgegeben.',
        responseBody: error.message,
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message:
            'Die Antwort von Ollama dauert zu lange. Bitte erneut versuchen.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        message:
            'Ollama konnte nicht erreicht werden. Bitte Verbindung prüfen.',
      );
    }
  }
}
