import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

/// Bolha de mensagem estilo WhatsApp.
///
/// - [ChatSender.bot] → bolha à esquerda, fundo cinza.
/// - [ChatSender.user] → bolha à direita, fundo destaque.
/// - Tipos de ação exibem botões inline.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final void Function(String action)? onAction;
  final void Function(String field, String currentText, String messageId)? onEditMessage;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onAction,
    this.onEditMessage,
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
              onLongPress: _isUser && _editableField != null
                  ? () => onEditMessage?.call(_editableField!, message.content, message.id)
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isUser
                      ? const Color(0xFF075E54)
                      : const Color(0xFF2A2D3E),
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
                      const Text(
                        'Assistente',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_dataRows != null && _dataRows!.isNotEmpty && !_isUser) ...[
                      ..._dataRows!.map((row) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: row['label'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${row['value']}',
                                  style: const TextStyle(
                                    color: Color(0xFF00BFA5),
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
                    Text(
                      message.content,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    if (message.type == ChatMessageType.contactPicker) ...[
                      const SizedBox(height: 8),
                      Text(
                        ChatBudgetStrings.contactPickerHint,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
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
                          const Icon(Icons.edit, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            'Toque e segure para editar',
                            style: TextStyle(
                              color: Colors.white.withAlpha(179),
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

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Colors.cyan,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.support_agent, size: 18, color: Colors.white),
    );
  }

  Widget _buildExtraContent() {
    switch (message.type) {
      case ChatMessageType.inlineButtons:
        return _InlineButtons(
          actions: _parseActions(),
          onTap: onAction,
        );
      case ChatMessageType.contactPicker:
        return _ContactPickerButton(onTap: onAction);
      case ChatMessageType.action:
        return _ActionButton(
          label: message.payload?['label'] as String? ?? 'Abrir',
          action: message.payload?['action'] as String? ?? 'action',
          onTap: onAction,
        );
      case ChatMessageType.productList:
        return _ProductListActions(
          onEdit: () => onAction?.call('edit_products'),
        );
      case ChatMessageType.image:
        return _ImageContent(
          payload: message.payload,
          onTap: onAction,
        );
      case ChatMessageType.text:
      default:
        return const SizedBox.shrink();
    }
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
      children: actions.map((label) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () => onTap?.call(label),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        label: const Text('Escolher contato'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () => onTap?.call('pick_contact'),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String action;
  final void Function(String)? onTap;

  const _ActionButton({
    required this.label,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () => onTap?.call(action),
      ),
    );
  }
}

class _ProductListActions extends StatelessWidget {
  final VoidCallback onEdit;

  const _ProductListActions({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.edit, size: 16, color: Colors.cyanAccent),
        label: const Text('Editar seleção',
            style: TextStyle(color: Colors.cyanAccent)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.cyanAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onEdit,
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
    final changeLabel = payload!['changeLabel'] as String? ?? 'Alterar logo';

    Widget imageWidget;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      final bytes = base64Decode(imageBase64);
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
      );
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
            constraints: const BoxConstraints(
              maxWidth: 240,
              maxHeight: 240,
            ),
            child: imageWidget,
          ),
        ),
        if (changeAction != null) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 16),
            label: Text(changeLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => onTap?.call(changeAction),
          ),
        ],
      ],
    );
  }
}
