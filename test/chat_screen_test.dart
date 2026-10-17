import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_message.dart';
import 'package:bienenplan_frontend/features/chat/data/chat_repository.dart';
import 'package:bienenplan_frontend/features/chat/presentation/chat_screen.dart';

void main() {
  testWidgets('sends a profile message without a project and renders answer', (
    tester,
  ) async {
    final repository = _FakeChatRepository();
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(repository: repository)),
    );

    await tester.enterText(
      find.byKey(const ValueKey('chat-message-field')),
      'Was weißt du?',
    );
    await tester.tap(find.byKey(const ValueKey('chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Alle aktiven Projekte'), findsOneWidget);
    expect(
      find.textContaining('Archivierte Projekte sind ausgeschlossen'),
      findsOneWidget,
    );
    expect(repository.messages?.single.content, 'Was weißt du?');
    expect(find.text('Was weißt du?'), findsOneWidget);
    expect(find.text('Antwort aus Ollama'), findsOneWidget);
  });
}

class _FakeChatRepository implements ChatRepositoryContract {
  List<ChatMessage>? messages;

  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages) async {
    this.messages = messages;
    return const ChatMessage(role: 'assistant', content: 'Antwort aus Ollama');
  }
}
