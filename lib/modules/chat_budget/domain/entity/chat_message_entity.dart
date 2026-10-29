/// Entidade pura da mensagem no chat.
enum ChatSender { bot, user, system }

/// Tipos de mensagem suportados no chat.
enum ChatMessageType {
  text,
  action,
  productList,
  contactPicker,
  inlineButtons,
}

/// Representa uma mensagem no chat do assistente de orçamentos.
class ChatMessageEntity {
  final String id;
  final ChatSender sender;
  final ChatMessageType type;
  final String content;
  final Map<String, dynamic>? payload;
  final DateTime timestamp;

  const ChatMessageEntity({
    required this.id,
    required this.sender,
    required this.type,
    required this.content,
    this.payload,
    required this.timestamp,
  });

  ChatMessageEntity copyWith({
    String? id,
    ChatSender? sender,
    ChatMessageType? type,
    String? content,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      content: content ?? this.content,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
