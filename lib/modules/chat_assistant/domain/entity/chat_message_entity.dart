/// Entidade pura da mensagem no chat.
enum ChatSender { bot, user, system }

/// Tipos de mensagem suportados no chat.
enum ChatMessageType {
  text,
  action,
  productList,
  contactPicker,
  inlineButtons,
  image,
  optionList,

  /// Card com lista de orçamentos vinda da IA (payload: title, footer, items).
  budgetList,

  /// Card de resumo do mês vindo da IA (payload: title, total, rows).
  summaryCard,

  /// Card do relatório de recibos por período (payload: ver
  /// `ChatReceiptsReportCard`).
  receiptsReportCard,

  /// Anexo enviado pelo usuário (payload: `files[{path,name,type,size}]`,
  /// `caption`).
  attachment,
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

  /// Mensagem do bot com opções em botões empilhados ([ChatMessageType.optionList]).
  ///
  /// Cada label recebe como `value` sua posição (`1..n`) — o mesmo número que o
  /// usuário digitaria. [backLabel], quando informado, vira a última opção com
  /// `value` `0`. [step] identifica o passo do fluxo ao qual o menu pertence.
  /// [highlight], quando informado, é exibido em destaque dentro do texto.
  factory ChatMessageEntity.botOptions({
    required String content,
    required List<String> labels,
    required String step,
    String? backLabel,
    String? highlight,
    List<String>? values,
  }) {
    final now = DateTime.now();
    return ChatMessageEntity(
      id: now.millisecondsSinceEpoch.toString(),
      sender: ChatSender.bot,
      type: ChatMessageType.optionList,
      content: content,
      payload: {
        'options': [
          for (var i = 0; i < labels.length; i++)
            {'label': labels[i], 'value': values?[i] ?? '${i + 1}'},
          if (backLabel != null) {'label': backLabel, 'value': '0'},
        ],
        'optionsStep': step,
        if (highlight != null && highlight.isNotEmpty) 'highlight': highlight,
      },
      timestamp: now,
    );
  }

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
