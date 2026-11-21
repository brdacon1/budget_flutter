import 'package:oflite/shared/common/constants/colors.dart';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_attachment_bubble.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_budget_list_card.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_message_option_buttons.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_month_summary_card.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_receipts_report_card.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Bolha de mensagem estilo WhatsApp.
///
/// - [ChatSender.bot] → bolha à esquerda, fundo cinza.
/// - [ChatSender.user] → bolha à direita, fundo destaque.
/// - Tipos de ação exibem botões inline.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final void Function(String action)? onAction;
  final void Function(String field, String currentText, String messageId)?
  onEditMessage;
  final void Function(String value, String label)? onOptionSelect;

  /// Toque num anexo enviado (imagem/PDF).
  final void Function(ProofAttachment file)? onOpenAttachment;

  /// `false` deixa todos os botões da mensagem desativados (opacos).
  final bool buttonsEnabled;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onAction,
    this.onEditMessage,
    this.onOptionSelect,
    this.onOpenAttachment,
    this.buttonsEnabled = false,
  });

  bool get _isUser => message.sender == ChatSender.user;

  List<Map<String, String>>? get _dataRows {
    final p = message.payload;
    if (p == null) return null;
    final raw = p['dataRows'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) {
        return <String, String>{
          'label': e['label']?.toString() ?? '',
          'value': e['value']?.toString() ?? '',
        };
      }).toList();
    }
    return null;
  }

  String? get _editableField {
    final p = message.payload;
    if (p == null) return null;
    return p['editableField'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) _buildAvatar(),
          const SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onLongPress:
                  _isUser && _editableField != null
                      ? () => onEditMessage?.call(
                        _editableField!,
                        message.content,
                        message.id,
                      )
                      : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _isUser ? chatUserBubbleColor : secondaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(_isUser ? 16 : 4),
                    bottomRight: Radius.circular(_isUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isUser) ...[
                      Text(
                        ChatAssistantStrings.assistantTitle,
                        style: const TextStyle(
                          color: chatHighlightColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_dataRows != null &&
                        _dataRows!.isNotEmpty &&
                        !_isUser) ...[
                      ..._dataRows!.map((row) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: row['label'],
                                  style: const TextStyle(
                                    color: whiteColor,
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${row['value']}',
                                  style: const TextStyle(
                                    color: chatSendButtonColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                    if (message.type == ChatMessageType.attachment)
                      ChatAttachmentBubble(
                        payload: message.payload ?? const {},
                        onOpen: onOpenAttachment,
                      ),
                    if (message.type != ChatMessageType.attachment ||
                        message.content.isNotEmpty)
                      Text.rich(
                        _buildMessageText(message.content),
                        style: const TextStyle(color: whiteColor, fontSize: 15),
                      ),
                    if (message.type == ChatMessageType.contactPicker) ...[
                      const SizedBox(height: 8),
                      Text(
                        ChatAssistantStrings.contactPickerHint,
                        style: TextStyle(
                          color: whiteColor.withAlpha(200),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (_hasSelectableOptions) ...[
                      const SizedBox(height: 8),
                      Text(
                        ChatAssistantStrings.typeOptionInstruction,
                        style: TextStyle(
                          color: whiteColor.withAlpha(200),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (_isUser && _editableField != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit,
                            size: 12,
                            color: chatMutedIconColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ChatAssistantStrings.holdToEdit,
                            style: TextStyle(
                              color: whiteColor.withAlpha(179),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ] else if (message.type != ChatMessageType.contactPicker)
                      const SizedBox(height: 6),
                    _buildExtraContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _highlightStyle = TextStyle(
    color: chatSendButtonColor,
    fontWeight: FontWeight.bold,
  );

  /// Valor do dado (ex: nome atual da empresa) exibido em destaque no texto.
  String? get _highlight {
    final value = message.payload?['highlight'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Quebra a linha nas ocorrências de [_highlight], destacando-as.
  List<TextSpan> _highlightSpans(String line) {
    final highlight = _highlight;
    if (highlight == null || !line.contains(highlight)) {
      return [TextSpan(text: line)];
    }
    final parts = line.split(highlight);
    return [
      for (var i = 0; i < parts.length; i++) ...[
        if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
        if (i < parts.length - 1)
          TextSpan(text: highlight, style: _highlightStyle),
      ],
    ];
  }

  TextSpan _buildMessageText(String text) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = RegExp(r'^(\d+\.\s*)(.*)$').firstMatch(line);
      if (match != null) {
        spans.add(
          TextSpan(
            text: '${match.group(1)}${match.group(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        spans.addAll(_highlightSpans(line));
      }
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return TextSpan(children: spans);
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: chatBotAvatarColor,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.support_agent, size: 18, color: whiteColor),
    );
  }

  Widget _buildExtraContent() {
    final onAction = buttonsEnabled ? this.onAction : null;
    switch (message.type) {
      case ChatMessageType.inlineButtons:
        final backLabel = message.payload?['backLabel'] as String?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InlineButtons(actions: _parseActions(), onTap: onAction),
            if (backLabel != null)
              ChatMessageOptionButtons(
                options: [
                  {'label': backLabel, 'value': '0'},
                ],
                enabled: buttonsEnabled,
                onSelect: (_, __) => onAction?.call('back_to_menu'),
              ),
          ],
        );
      case ChatMessageType.contactPicker:
        return _ContactPickerButton(onTap: onAction);
      case ChatMessageType.action:
        final actionBackLabel = message.payload?['backLabel'] as String?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionButton(
              label:
                  message.payload?['label'] as String? ??
                  ChatAssistantStrings.openLabel,
              action: message.payload?['action'] as String? ?? 'action',
              onTap: onAction,
            ),
            if (actionBackLabel != null)
              ChatMessageOptionButtons(
                options: [
                  {'label': actionBackLabel, 'value': '0'},
                ],
                enabled: buttonsEnabled,
                onSelect: (_, __) => onAction?.call('back_to_menu'),
              ),
          ],
        );
      case ChatMessageType.productList:
        return _ProductListActions(
          onEdit: onAction == null ? null : () => onAction('edit_products'),
        );
      case ChatMessageType.image:
        return _ImageContent(payload: message.payload, onTap: onAction);
      case ChatMessageType.optionList:
        return ChatMessageOptionButtons(
          options: _parseOptions(),
          enabled: buttonsEnabled,
          onSelect: onOptionSelect,
        );
      case ChatMessageType.budgetList:
        return ChatBudgetListCard(
          payload: message.payload ?? {},
          onTap: onAction,
        );
      case ChatMessageType.summaryCard:
        return ChatMonthSummaryCard(payload: message.payload ?? {});
      case ChatMessageType.receiptsReportCard:
        return ChatReceiptsReportCard(
          payload: message.payload ?? {},
          onTap: onAction,
        );
      case ChatMessageType.text:
      case ChatMessageType.attachment:
        return const SizedBox.shrink();
    }
  }

  /// Dica "Toque na opção" só quando há opções além do "Voltar ao menu".
  bool get _hasSelectableOptions =>
      message.type == ChatMessageType.optionList &&
      _parseOptions().any((o) => o['value'] != '0');

  List<Map<String, String>> _parseOptions() {
    final raw = message.payload?['options'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) {
      return <String, String>{
        'label': e['label']?.toString() ?? '',
        'value': e['value']?.toString() ?? '',
      };
    }).toList();
  }

  List<String> _parseActions() {
    final payload = message.payload;
    if (payload == null) return [];
    final raw = payload['actions'];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return [];
  }
}

// ---------------------------------------------------------------------------
// Sub-componentes de ação inline
// ---------------------------------------------------------------------------

class _InlineButtons extends StatelessWidget {
  final List<String> actions;
  final void Function(String)? onTap;

  const _InlineButtons({required this.actions, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          actions.map((label) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: chatSendButtonColor,
                foregroundColor: blackColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: onTap == null ? null : () => onTap!(label),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
    );
  }
}

class _ContactPickerButton extends StatelessWidget {
  final void Function(String)? onTap;

  const _ContactPickerButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.contacts, size: 18),
        label: Text(ChatAssistantStrings.pickContactLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: chatSendButtonColor,
          foregroundColor: blackColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onTap == null ? null : () => onTap!('pick_contact'),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String action;
  final void Function(String)? onTap;

  const _ActionButton({required this.label, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: chatSendButtonColor,
          foregroundColor: blackColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onTap == null ? null : () => onTap!(action),
      ),
    );
  }
}

class _ProductListActions extends StatelessWidget {
  final VoidCallback? onEdit;

  const _ProductListActions({this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Opacity(
        opacity: onEdit == null ? 0.4 : 1,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.edit, size: 16, color: chatHighlightColor),
          label: Text(
            ChatAssistantStrings.editSelection,
            style: const TextStyle(color: chatHighlightColor),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: chatHighlightColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  final Map<String, dynamic>? payload;
  final void Function(String action)? onTap;

  const _ImageContent({this.payload, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (payload == null) return const SizedBox.shrink();

    final imageBase64 = payload!['imageBase64'] as String?;
    final imageUrl = payload!['imageUrl'] as String?;
    final changeAction = payload!['changeAction'] as String?;
    final changeLabel =
        payload!['changeLabel'] as String? ??
        ChatAssistantStrings.changeLogoLabel;

    Widget imageWidget;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      final bytes = base64Decode(imageBase64);
      imageWidget = Image.memory(bytes, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = Image.network(imageUrl, fit: BoxFit.cover);
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
            child: imageWidget,
          ),
        ),
        if (changeAction != null) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 16),
            label: Text(changeLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: chatSendButtonColor,
              foregroundColor: blackColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: onTap == null ? null : () => onTap!(changeAction),
          ),
        ],
      ],
    );
  }
}
