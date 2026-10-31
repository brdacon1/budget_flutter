import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/chat_assistant_view_model.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_message_bubble.dart';
import 'package:oflite/modules/chat_assistant/presenter/enum/chat_flow_step_enum.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/comment/presenter/comment_list_view.dart';
import 'package:oflite/modules/budget/budget_list_items/presenter/budget_list_items_view.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/image/presenter/image_edit_view.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view.dart';
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/modules/product/product_price_creator/presenter/product_price_creator_view.dart';
import 'package:oflite/modules/product/product_price_list/presenter/product_price_list_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;
import 'package:oflite/shared/design_pattern/result.dart';


/// Tela do assistente de orçamentos (chat estilo WhatsApp).
class ChatAssistantView extends StatefulWidget {
  const ChatAssistantView({super.key});

  @override
  State<ChatAssistantView> createState() => _ChatAssistantViewState();
}

class _ChatAssistantViewState extends State<ChatAssistantView> {
  late final ChatAssistantViewModel _vm;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _vm = getIt<ChatAssistantViewModel>();
    _vm.addListener(_onVmChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.initializeChat.execute();
    });
  }

  void _onVmChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
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

  /// Abre a tela de itens do orçamento (edita/exclui/adiciona itens).
  Future<void> _openBudgetItems() async {
    final budget = _vm.draftBudget;
    if (budget == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetListItemsView(item: budget),
      ),
    );

    // Ao voltar, os itens já foram salvos/editados na tela nativa.
    // Avança direto para a pergunta de comentários.
    await _vm.goToCommentsAfterProductEdit();
  }

  Future<void> _openComments() async {
    final budget = _vm.draftBudget;
    if (budget == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentListView(item: budget),
      ),
    );

    // Ao voltar da tela de comentários, finaliza o orçamento
    await _vm.finalizeAfterComments();
  }

  /// Processa navegações pendentes disparadas pela ViewModel (telas/modais externas).
  Future<void> _handlePendingNavigation() async {
    final nav = _vm.pendingNavigation;
    if (nav == null) return;

    // Limpa imediatamente para evitar re-executar no próximo build
    _vm.clearPendingNavigation();

    switch (nav) {
      case 'open_price_list':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProductPriceListView(fromMenu: true),
          ),
        );
        if (mounted) {
          await _vm.resetChatCommand.execute();
        }
        break;
      case 'open_product_creator':
        _openProductCreator();
        break;
      case 'open_pdf_edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PdfEditView(),
          ),
        );
        break;
      case 'open_change_name':
        _openChangeNameModal();
        break;
      case 'open_logo_view':
        break;
      case 'open_logo_edit':
        await _openLogoEditFlow();
        break;
    }
  }

  Future<void> _openProductCreator() async {
    final result = await showProductPriceCreatorBottomModal(
      context,
      item: ProductPriceModel(),
    );

    if (result == true) {
      // Modal salvou com sucesso — notifica o ViewModel para buscar o produto
      await _vm.onProductCreatedFromChat();
    }
  }

  Future<void> _openChangeNameModal() async {
    final displayAlert = getIt<DisplayAlertRepository>();
    final newName = await displayAlert.dialogChangeName(context);
    if (!mounted) return;
    await _vm.onUsernameChanged(newName);
  }

  Future<void> _openLogoEditFlow() async {
    final isSubscribed = UID.autoRenewing ?? false;
    if (!isSubscribed) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionView()),
      );
    } else {
      final pdfRepo = getIt<PdfRepository>();
      final result = await pdfRepo.fetchInformationEnterprise();
      final owner = result is Ok<OwnerPdf> ? result.value : OwnerPdf();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageEditView(owner: owner, title: 'Editar Logo'),
        ),
      );
    }

    if (!mounted) return;
    // Ao voltar, notifica o ViewModel para confirmar e voltar ao menu de PDF
    await _vm.onLogoUpdated();
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
      body: Builder(
        builder: (context) {
          _scrollToBottom();

          // Processa navegação pendente da ViewModel (fora do build)
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) await _handlePendingNavigation();
          });

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
                      onEditMessage: (field, text, msgId) => _vm.prepareEditMessage(field, text, msgId),
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
        numberController: _vm.numberController,
        cityController: _vm.cityController,
        neighborhoodController: _vm.neighborhoodController,
        isCorrecting: _vm.isCorrectingAddress,
        onSubmit: () => _vm.submitManualAddressCommand.execute(),
        onCancelAndProceed: () => _vm.handleAction('cancel_and_proceed'),
      );
    }

    // Dá foco automático no input quando entra em modo de edição
    if (_vm.isEditingMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputFocusNode.requestFocus();
      });
    }

    return _EditAwareInputBar(
      controller: _vm.textController,
      focusNode: _inputFocusNode,
      isEditing: _vm.isEditingMessage,
      onCancelEdit: () => _vm.cancelEdit(),
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
        if (_vm.step == ChatFlowStep.askComments) {
          await _openComments();
        } else {
          await _vm.handleAction('SIM');
        }
        break;
      case 'Sim':
        if (_vm.step == ChatFlowStep.pdfEditConfirmEntry) {
          await _vm.sendTextCommand.execute('Sim');
        } else {
          await _vm.handleAction(action);
        }
        break;
      case 'NÃO':
        if (_vm.step == ChatFlowStep.askComments) {
          await _vm.handleAction('NÃO');
        } else {
          await _vm.skipAddressCommand.execute();
        }
        break;
      case 'Não':
        if (_vm.step == ChatFlowStep.pdfEditConfirmEntry) {
          await _vm.sendTextCommand.execute('Não');
        } else if (_vm.step == ChatFlowStep.askComments) {
          await _vm.handleAction('NÃO');
        } else {
          await _vm.skipAddressCommand.execute();
        }
        break;
      case 'open_products':
        await _openBudgetItems();
        break;
      case 'share_link':
        await _vm.shareLinkCommand.execute();
        break;
      case 'edit_products':
        await _openBudgetItems();
        break;
      case 'edit_comments':
      case 'Editar comentários':
        await _openComments();
        break;
      case 'finalize_budget':
      case 'Finalizar e gerar link':
        await _vm.handleAction('finalize_budget');
        break;
      case 'cancel_and_proceed':
        await _vm.handleAction('cancel_and_proceed');
        break;
      case 'open_logo_edit':
        await _openLogoEditFlow();
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
// Input que mostra estado de edição inline (estilo WhatsApp)
// ---------------------------------------------------------------------------

class _EditAwareInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;
  final bool enabled;
  final bool isEditing;

  const _EditAwareInputBar({
    required this.controller,
    required this.onSend,
    required this.onCancelEdit,
    this.focusNode,
    this.enabled = true,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 14, color: Colors.cyanAccent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Editando mensagem',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelEdit,
                      child: const Icon(Icons.close, size: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isEditing ? 'Edite a mensagem...' : 'Digite uma mensagem...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF2A2D3E),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: const Color(0xFF00BFA5),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onSend : null,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.send, color: Colors.black, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulário de endereço manual (com suporte a correção de CEP)
// ---------------------------------------------------------------------------

class _ManualAddressForm extends StatelessWidget {
  final TextEditingController streetController;
  final TextEditingController numberController;
  final TextEditingController cityController;
  final TextEditingController neighborhoodController;
  final bool isCorrecting;
  final VoidCallback onSubmit;
  final VoidCallback onCancelAndProceed;

  const _ManualAddressForm({
    required this.streetController,
    required this.numberController,
    required this.cityController,
    required this.neighborhoodController,
    required this.isCorrecting,
    required this.onSubmit,
    required this.onCancelAndProceed,
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
            if (isCorrecting)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.cyanAccent),
                      foregroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onCancelAndProceed,
                    child: Text(
                      ChatBudgetStrings.cancelAndProceed,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildField(streetController, ChatBudgetStrings.streetField),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _buildField(numberController, ChatBudgetStrings.numberField, keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildField(cityController, ChatBudgetStrings.cityField),
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

  Widget _buildField(TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
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
