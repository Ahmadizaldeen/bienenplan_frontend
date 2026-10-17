import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/core/api/api_client.dart';
import 'package:bienenplan_frontend/core/api/api_endpoints.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_message.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_repository.dart';

void main() {
  test(
    'posts the conversation to the authenticated profile chat endpoint',
    () async {
      final client = _RecordingApiClient();
      final repository = ChatRepository(apiClient: client);

      final answer = await repository.sendMessage([
        const ChatMessage(role: 'user', content: 'Alle meine Projekte'),
      ]);

      expect(client.url, ApiEndpoints.chat);
      expect(client.body, {
        'messages': [
          {'role': 'user', 'content': 'Alle meine Projekte'},
        ],
      });
      expect(client.timeout, const Duration(seconds: 190));
      expect(answer.content, 'Profilantwort');
    },
  );
}

class _RecordingApiClient extends ApiClient {
  String? url;
  Map<String, dynamic>? body;
  Duration? timeout;

  @override
  Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    this.url = url;
    this.body = body;
    this.timeout = timeout;
    return {
      'message': {'role': 'assistant', 'content': 'Profilantwort'},
    };
  }
}
