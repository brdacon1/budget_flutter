import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart';
import 'package:oflite/modules/chat_budget/presenter/chat_assistant/components/chat_input_bar.dart';
import 'package:oflite/modules/chat_budget/presenter/chat_assistant/components/chat_message_bubble.dart';
import 'package:oflite/modules/product/product_price_list/presenter/product_price_list_view.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/items_budget.dart';

/// Tela do assistente de orçamentos (chat estilo WhatsApp).
class ChatAssistantView extends StatefulWidget {
  const ChatAssistantView({super.key});

  @override
  State<ChatAssistantView> createState() => _ChatAssistantViewState();
}

class _ChatAssistantViewState extends State<ChatAssistantView> {
  late final ChatAssistantViewModel _vm;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = getIt<ChatAssistantViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.initializeChat.execute();
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openProductSelection({bool isEdit = false}) async {
    final budget = _vm.draftBudget;
    if (budget == null) return;

    final result = await Navigator.push<List<ItemsBudget>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductPriceListView(
          item: budget,
          fromMenu: false,
          selectionMode: true,
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (isEdit) {
        await _vm.editProductsCommand.execute(result);
      } else {
        await _vm.confirmProductsCommand.execute(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.cyan,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar conversa',
            onPressed: () => _vm.resetChatCommand.execute(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (context, _) {
          _scrollToBottom();

          // Mostra SnackBar quando share dá erro
          if (_vm.shareLinkCommand.error && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final msg = _vm.shareErrorMessage ?? 'Erro ao compartilhar';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _vm.clearShareError();
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _vm.messages.length,
                  itemBuilder: (context, index) {
                    final msg = _vm.messages[index];
                    return ChatMessageBubble(
                      message: msg,
                      onAction: (action) => _handleAction(action, msg),
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    final step = _vm.step;

    if (step == ChatFlowStep.askStreetManual) {
      return _ManualAddressForm(
        streetController: _vm.streetController,
        cityController: _vm.cityController,
        neighborhoodController: _vm.neighborhoodController,
        onSubmit: () => _vm.submitManualAddressCommand.execute(),
      );
    }

    return ChatInputBar(
      controller: _vm.textController,
      enabled: !_vm.isLoading &&
          step != ChatFlowStep.askAddress &&
          step != ChatFlowStep.reviewProducts &&
          step != ChatFlowStep.shareLink,
      onSend: () {
        final text = _vm.textController.text.trim();
        if (text.isNotEmpty) {
          _vm.textController.clear();
          _vm.sendTextCommand.execute(text);
        }
      },
    );
  }

  void _handleAction(String action, ChatMessageEntity msg) async {
    switch (action) {
      case 'pick_contact':
        await _vm.pickContactCommand.execute();
        break;
      case 'SIM':
        await _vm.handleAction('SIM');
        break;
      case 'NÃO':
        await _vm.skipAddressCommand.execute();
        break;
      case 'open_products':
        await _openProductSelection();
        break;
      case 'share_link':
        await _vm.shareLinkCommand.execute();
        break;
      case 'edit_products':
        await _openProductSelection(isEdit: true);
        break;
      default:
        // Delega para o ViewModel ações que não precisam de interação com a UI
        // (ex: Confirmar endereço, Corrigir endereço, etc.)
        await _vm.handleAction(action);
        break;
    }
  }
}

// ---------------------------------------------------------------------------
// Formulário de endereço manual (rótulo + 3 campos + botão)
// ---------------------------------------------------------------------------

class _ManualAddressForm extends StatelessWidget {
  final TextEditingController streetController;
  final TextEditingController cityController;
  final TextEditingController neighborhoodController;
  final VoidCallback onSubmit;

  const _ManualAddressForm({
    required this.streetController,
    required this.cityController,
    required this.neighborhoodController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(streetController, 'Rua e número'),
            const SizedBox(height: 8),
            _buildField(cityController, 'Cidade'),
            const SizedBox(height: 8),
            _buildField(neighborhoodController, 'Bairro (opcional)'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onSubmit,
                child: const Text(
                  'Confirmar endereço',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF2A2D3E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
