import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_message.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_repository.dart';
import 'package:bienenplan_frontend/features/chat/presentation/chat_screen.dart';
import 'package:bienenplan_frontend/features/projects/data/project_model.dart';

void main() {
  testWidgets('sends a message for the selected project and renders answer', (
    tester,
  ) async {
    final repository = _FakeChatRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          project: const Project(id: 12, name: 'Testprojekt'),
          repository: repository,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('chat-message-field')),
      'Was weißt du?',
    );
    await tester.tap(find.byKey(const ValueKey('chat-send-button')));
    await tester.pumpAndSettle();

    expect(repository.projectId, 12);
    expect(repository.messages?.single.content, 'Was weißt du?');
    expect(find.text('Was weißt du?'), findsOneWidget);
    expect(find.text('Antwort aus Ollama'), findsOneWidget);
  });
}

class _FakeChatRepository implements ChatRepositoryContract {
  int? projectId;
  List<ChatMessage>? messages;

  @override
  Future<ChatMessage> sendMessage(
    int projectId,
    List<ChatMessage> messages,
  ) async {
    this.projectId = projectId;
    this.messages = messages;
    return const ChatMessage(role: 'assistant', content: 'Antwort aus Ollama');
  }
}
