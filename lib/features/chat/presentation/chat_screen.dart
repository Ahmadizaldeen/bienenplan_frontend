import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../application/chat_controller.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.repository});

  final ChatRepositoryContract? repository;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Jeder Aufruf startet einen neuen Verlauf; beim Verlassen geht er verloren.
  late final ChatController _controller = ChatController(
    repository: widget.repository,
  );
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await _controller.sendMessage(_messageController.text);
    if (!mounted) return;
    if (sent) _messageController.clear();
    // Erst nach dem Neuaufbau der Nachrichtenliste zu deren Ende scrollen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BienenPlan-Assistent'),
            Text(
              'Alle aktiven Projekte',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => IconButton(
              key: const ValueKey('chat-new-conversation'),
              tooltip: 'Neuen Chat starten',
              onPressed: _controller.isSending ? null : _controller.clear,
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: scheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Der Assistent berücksichtigt alle für dich zugänglichen aktiven Projekte mit deinen sichtbaren Aufgaben und Unteraufgaben. Archivierte Projekte sind ausgeschlossen. Statistiken beziehen sich nur auf diese sichtbaren Daten.',
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (_controller.messages.isEmpty)
                      const _AssistantBubble(
                        message: ChatMessage(
                          role: 'assistant',
                          content: 'Hallo! Ich bin der BienenPlan-Assistent. Was möchtest du wissen?',
                        ),
                      ),
                    for (final message in _controller.messages)
                      _MessageBubble(message: message),
                    if (_controller.isSending)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    if (_controller.errorMessage case final error?)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          error,
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chat-message-field'),
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 4000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Nachricht schreiben',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => IconButton.filled(
                      key: const ValueKey('chat-send-button'),
                      tooltip: 'Nachricht senden',
                      onPressed: _controller.isSending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return message.role == 'assistant'
        ? _AssistantBubble(message: message)
        : Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(message.content),
            ),
          );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(message.content),
      ),
    );
  }
}
