import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatRepositoryContract? repository})
    : _repository = repository ?? ChatRepository();

  // Der Verlauf bleibt nur erhalten, solange der Chat-Bildschirm geöffnet ist.
  final ChatRepositoryContract _repository;
  List<ChatMessage> _messages = const [];
  bool _isSending = false;
  String? _errorMessage;
  bool _disposed = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<bool> sendMessage(String text) async {
    final content = text.trim();
    if (_disposed || _isSending || content.isEmpty) return false;
    if (content.length > 4000) {
      _errorMessage = 'Eine Nachricht darf höchstens 4.000 Zeichen enthalten.';
      _notify();
      return false;
    }
    if (_messages.length >= 20) {
      _errorMessage =
          'Der Chat ist zu lang. Bitte starten Sie einen neuen Chat.';
      _notify();
      return false;
    }
    // Das Backend begrenzt die Summe der Nachrichteninhalte in UTF-8-Bytes;
    // Antworten mit Mehrbyte-Zeichen verbrauchen daher mehr vom Nachrichtenlimit.
    final conversationBytes = _messages.fold<int>(
      0,
      (total, message) => total + utf8.encode(message.content).length,
    );
    if (conversationBytes + utf8.encode(content).length > 64000) {
      _errorMessage = 'Der Nachrichtenverlauf ist zu groß. Bitte starten Sie einen neuen Chat.';
      _notify();
      return false;
    }

    // Die Nutzernachricht sofort anzeigen und bei einem Fehler wieder entfernen.
    _messages = [..._messages, ChatMessage(role: 'user', content: content)];
    _isSending = true;
    _errorMessage = null;
    _notify();
    try {
      final answer = await _repository.sendMessage(_messages);
      if (_disposed) return false;
      _messages = [..._messages, answer];
      return true;
    } on ApiException catch (error) {
      if (!_disposed) {
        // Verlauf zurücksetzen, damit dieselbe Nachricht erneut gesendet werden kann.
        _messages = _messages.sublist(0, _messages.length - 1);
        _errorMessage = error.message;
      }
      return false;
    } finally {
      if (!_disposed) {
        _isSending = false;
        _notify();
      }
    }
  }

  void clear() {
    if (_disposed || _isSending) return;
    _messages = const [];
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
