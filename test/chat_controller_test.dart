import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/features/chat/application/chat_controller.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_message.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_repository.dart';

void main() {
  group('ChatController', () {
    test(
      'sends the profile conversation without a project, then appends answer',
      () async {
        final repository = _FakeChatRepository();
        final controller = ChatController(repository: repository);

        final sent = await controller.sendMessage('  Hallo  ');

        expect(sent, isTrue);
        expect(
          repository.messages?.map((message) => message.toJson()).toList(),
          [
            {'role': 'user', 'content': 'Hallo'},
          ],
        );
        expect(
          controller.messages.map((message) => message.toJson()).toList(),
          [
            {'role': 'user', 'content': 'Hallo'},
            {'role': 'assistant', 'content': 'Antwort'},
          ],
        );
        expect(controller.isSending, isFalse);
        controller.dispose();
      },
    );

    test('removes an unsent message and exposes API error', () async {
      final controller = ChatController(
        repository: _FakeChatRepository(fail: true),
      );

      expect(await controller.sendMessage('Hallo'), isFalse);
      expect(controller.messages, isEmpty);
      expect(controller.errorMessage, 'Ollama nicht erreichbar');
      controller.dispose();
    });

    test(
      'rejects a conversation that exceeds the backend byte limit',
      () async {
        final repository = _FakeChatRepository();
        final controller = ChatController(repository: repository);

        for (var index = 0; index < 8; index++) {
          expect(await controller.sendMessage('😀' * 1800), isTrue);
        }

        final sent = await controller.sendMessage('😀' * 1800);

        expect(sent, isFalse);
        expect(controller.errorMessage, contains('Nachrichtenverlauf'));
        controller.dispose();
      },
    );
  });
}

class _FakeChatRepository implements ChatRepositoryContract {
  _FakeChatRepository({this.fail = false});

  final bool fail;
  List<ChatMessage>? messages;

  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages) async {
    this.messages = messages;
    if (fail) {
      throw const ApiException(
        statusCode: 503,
        message: 'Ollama nicht erreichbar',
      );
    }
    return const ChatMessage(role: 'assistant', content: 'Antwort');
  }
}
