import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_duplicate_bottom_modal_widget.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/form/app_keyboard_dismiss_bar.dart';
import 'package:oflite/modules/budget/presenter/budget_tab/budget_tab_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_typing_indicator.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_list/budget_comment_list_view.dart';
import 'package:oflite/modules/budget/presenter/budget_list_items/budget_list_items_view.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/chat_assistant_view_model.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_budget_picker/chat_budget_picker_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_message_bubble.dart';
import 'package:oflite/modules/chat_assistant/presenter/enum/chat_flow_step_enum.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/image/presenter/image_edit_view.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/pdf/presenter/pdf_budget/pdf_budget_view.dart';
import 'package:oflite/modules/pdf/presenter/pdf_edit/presenter/pdf_edit_view.dart';
import 'package:oflite/modules/pdf/presenter/pdf_model_select/presenter/pdf_model_select_view.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/modules/product/presenter/product_price_list/product_price_list_view.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/receipt_list_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_attachment_panel.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/chat_media_picker_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_proof_preview/chat_proof_preview_view.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_list/payment_proof_list_view.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_viewer/payment_proof_viewer_view.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';

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
    _inputFocusNode.addListener(_onInputFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _vm.initializeChat.execute();
      // Câmera/fotos pedidas logo ao abrir o chat (modo IA).
      await _vm.ensureMediaPermissions();
      await _consumeSharedProof();
    });
  }

  // ------------------------------------------------------------------
  // Comprovantes (§15 do CHAT_AI_AGENT_PLAN)
  // ------------------------------------------------------------------

  /// Arquivos vindos da folha de compartilhamento → prévia → chat.
  Future<void> _consumeSharedProof() async {
    final shared = _vm.takeSharedProof();
    if (shared == null || !mounted) return;
    await _previewAndSend(shared, origin: PaymentProofOrigin.share);
  }

  void _showProofIssue(ProofAttachmentValidation v) {
    final alert = getIt<DisplayAlertRepository>();
    // Arquivos cortados (só os 2 primeiros / só o PDF) = aviso; recusa = erro.
    final isWarning = v.issue == null || v.issue == ProofAttachmentIssue.mixed;
    final msg = switch (v.issue) {
      ProofAttachmentIssue.tooBig => PaymentProofStrings.tooBig,
      ProofAttachmentIssue.invalidType => PaymentProofStrings.invalidType,
      ProofAttachmentIssue.mixed => PaymentProofStrings.mixedTypes,
      ProofAttachmentIssue.empty => null,
      null => v.trimmed ? PaymentProofStrings.onlyFirstFiles : null,
    };
    if (msg == null || !mounted) return;
    if (isWarning) {
      alert.notificationWarning(context, PaymentProofStrings.warningTitle, msg);
    } else {
      alert.notificationError(context, PaymentProofStrings.errorTitle, msg);
    }
  }

  Future<void> _previewAndSend(
    ProofAttachmentValidation? v, {
    PaymentProofOrigin origin = PaymentProofOrigin.chat,
  }) async {
    if (v == null || !mounted) return;
    _showProofIssue(v);
    if (v.files.isEmpty || (v.issue != null && v.issue != ProofAttachmentIssue.mixed)) {
      return;
    }
    final result = await ChatProofPreviewView.show(
      context,
      v.files,
      onCrop: _vm.cropProofImage,
    );
    if (result == null || !mounted) return;
    await _vm.sendProofAttachments(
      result.files,
      result.caption,
      origin: origin,
    );
  }

  /// "+": painel de anexos em modal, por cima da tab bar.
  Future<void> _openAttachPanel() async {
    FocusScope.of(context).unfocus();
    final choice = await ChatAttachmentPanel.show(context);
    if (!mounted) return;
    switch (choice) {
      case ChatAttachmentChoice.photos:
        await _attachPhotos();
      case ChatAttachmentChoice.camera:
        await _attachCamera();
      case ChatAttachmentChoice.document:
        await _attachDocument();
      case null:
        break;
    }
  }

  Future<void> _attachPhotos() async {
    if (!await _vm.canUseMedia(camera: false) || !mounted) return;
    final result = await ChatMediaPickerView.show(context);
    if (result == null || !mounted) return;
    _showProofIssue(result.validation);
    if (!result.validation.isValid) return;
    await _vm.sendProofAttachments(result.validation.files, result.caption);
  }

  Future<void> _attachCamera() async {
    if (!await _vm.canUseMedia(camera: true) || !mounted) return;
    await _previewAndSend(await _vm.captureProofPhoto());
  }

  Future<void> _attachDocument() async {
    await _previewAndSend(await _vm.pickProofDocument());
  }

  Future<void> _pickBudgetForProof() async {
    final id = await ChatBudgetPickerView.show(context);
    if (!mounted) return;
    await _vm.onProofBudgetSelected(id);
  }

  Future<void> _openProofs(String budgetId) async {
    final budget = await _vm.budgetForNavigation(budgetId);
    if (budget == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentProofListView(item: budget)),
    );
  }

  void _openAttachment(ProofAttachment f) => PaymentProofViewerView.open(
    context,
    title: f.name,
    type: f.type,
    localPath: f.path,
  );

  /// Ao focar o campo, rola até o fim depois que o teclado sobe (a área
  /// da lista encolhe durante a animação do teclado).
  void _onInputFocusChanged() {
    if (!_inputFocusNode.hasFocus) return;
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _scrollToBottom();
    });
  }

  void _onVmChanged() {
    if (!mounted) return;
    if (_vm.mediaPermissionDenied) {
      _vm.consumeMediaPermissionDenied();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        getIt<DisplayAlertRepository>().notificationError(
          context,
          PaymentProofStrings.errorTitle,
          PaymentProofStrings.permissionDenied,
        );
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _scrollController.dispose();
    _inputFocusNode.removeListener(_onInputFocusChanged);
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
      MaterialPageRoute(builder: (_) => BudgetListItemsView(item: budget)),
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
      MaterialPageRoute(builder: (_) => BudgetCommentListView(item: budget)),
    );

    // Ao voltar da tela de comentários, finaliza o orçamento
    await _vm.finalizeAfterComments();
  }

  /// Abre o PDF do orçamento recém-criado (só compartilhar + voltar na nav).
  Future<void> _openBudgetPdf() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PdfBudgetView()),
    );
    getIt<BudgetRepository>().clearSelectBudget();
  }

  /// Processa navegações pendentes disparadas pela ViewModel (telas/modais externas).
  Future<void> _handlePendingNavigation() async {
    final nav = _vm.pendingNavigation;
    if (nav == null) return;

    // Limpa imediatamente para evitar re-executar no próximo build
    _vm.clearPendingNavigation();

    if (nav.startsWith('open_budget|')) {
      await _openBudget(nav.substring('open_budget|'.length));
      return;
    }
    if (nav.startsWith(ChatAssistantViewModel.findBudgetAction)) {
      await _findBudget(
        nav.substring(ChatAssistantViewModel.findBudgetAction.length),
      );
      return;
    }
    if (nav == ChatAssistantViewModel.openBudgetPdfAction) {
      await _openBudgetPdf();
      return;
    }
    if (nav == DispatchAgentToolUsecase.selectReceiptBudget) {
      await _pickBudgetForReceipts();
      return;
    }
    if (nav == ChatAssistantViewModel.selectProofBudgetAction) {
      await _pickBudgetForProof();
      return;
    }
    if (nav == DispatchAgentToolUsecase.selectDuplicateBudget) {
      await _pickBudgetToDuplicate();
      return;
    }

    switch (nav) {
      case 'open_price_list':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProductPriceListView(),
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
          MaterialPageRoute(builder: (_) => const PdfEditView()),
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
      case 'open_pdf_model_select':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PdfModelSelectView()),
        );
        if (!mounted) break;
        if (result == true) {
          await _vm.onPdfModelSelected();
        } else {
          await _vm.repeatCurrentMenu();
        }
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
    } else if (mounted) {
      // Cancelou — reexibe o menu, pois o anterior ficou opaco
      await _vm.repeatCurrentMenu();
    }
  }

  Future<void> _openChangeNameModal() async {
    final displayAlert = getIt<DisplayAlertRepository>();
    final newName = await displayAlert.dialogChangeName(context);
    if (!mounted) return;
    await _vm.onUsernameChanged(newName);
  }

  Future<void> _openLogoEditFlow() async {
    final isSubscribed =
        getIt<UserRepository>().selectUser.value?.autoRenewing ?? false;
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
    // Ao voltar, mostra a logo e reapresenta o menu da logo (igual a "Ver logo")
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
              child: const Icon(
                Icons.support_agent,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'online',
                  style: TextStyle(fontSize: 12, color: Colors.greenAccent),
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
          if ((_vm.shareLinkCommand.error ||
                  _vm.copyLinkCommand.error ||
                  _vm.generatePdfCommand.error) &&
              mounted) {
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

          return LayoutBuilder(
            builder: (context, _) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount:
                          _vm.messages.length + (_vm.isAiThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _vm.messages.length) {
                          return const ChatTypingIndicator();
                        }
                        final msg = _vm.messages[index];
                        return ChatMessageBubble(
                          message: msg,
                          onAction: (action) {
                            _vm.markButtonUsed(msg, action);
                            _handleAction(action, msg);
                          },
                          buttonsEnabled: _vm.isButtonsActive(msg),
                          onOpenAttachment: _openAttachment,
                          onOptionSelect: (value, label) {
                            _vm.markButtonUsed(msg, value);
                            _vm.selectOptionCommand.execute((
                              value: value,
                              label: label,
                              step:
                                  msg.payload?['optionsStep'] as String? ?? '',
                            ));
                          },
                          onEditMessage:
                              (field, text, msgId) =>
                                  _vm.prepareEditMessage(field, text, msgId),
                        );
                      },
                    ),
                  ),
                  AppKeyboardDismissBar(label: ChatBudgetStrings.closeKeyboard),
                  _buildInputArea(),
                ],
              );
            },
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
        cepController: _vm.isCorrectingAddress ? _vm.cepController : null,
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

    final bar = _EditAwareInputBar(
      onAttach: _vm.canAttach ? _openAttachPanel : null,
      controller: _vm.textController,
      focusNode: _inputFocusNode,
      isEditing: _vm.isEditingMessage,
      onCancelEdit: () => _vm.cancelEdit(),
      enabled:
          !_vm.isLoading &&
          step != ChatFlowStep.askAddress &&
          step != ChatFlowStep.reviewProducts &&
          step != ChatFlowStep.shareLink &&
          !_vm.isSavingProof,
      onSend: () {
        final text = _vm.textController.text.trim();
        if (text.isNotEmpty) {
          _vm.textController.clear();
          _vm.sendTextCommand.execute(text);
        }
      },
    );
    return bar;
  }

  /// Abre a tela do orçamento (card da IA ou tool `open_budget`).
  Future<void> _openBudget(String id) async {
    final budget = await _vm.budgetForNavigation(id);
    if (budget == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BudgetTabView(item: budget)),
    );
  }

  /// "Encontrar orçamentos": modal já buscando [name] no banco → tela do
  /// orçamento → ao voltar, oferece abrir de novo ou voltar ao menu.
  Future<void> _findBudget(String name) async {
    final id = await ChatBudgetPickerView.show(context, initialQuery: name);
    if (id == null || !mounted) return;
    await _openBudget(id);
    if (mounted) await _vm.onFoundBudgetClosed(id);
  }

  /// Modal de seleção → lista de recibos do orçamento escolhido. Ao voltar
  /// (ou fechar o modal) o chat fica na mensagem com "Selecionar orçamento".
  Future<void> _pickBudgetForReceipts() async {
    final id = await ChatBudgetPickerView.show(context);
    if (id == null || !mounted) return;
    await _openReceipts(id);
  }

  /// Modal de seleção → modal de opções de duplicação (o mesmo da lista de
  /// orçamentos). Fechar qualquer um dos dois não muda o chat.
  Future<void> _pickBudgetToDuplicate() async {
    final id = await ChatBudgetPickerView.show(context);
    if (id == null || !mounted) return;
    final budget = await _vm.budgetForNavigation(id);
    if (budget == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: transparentColor,
      builder:
          (dialogContext) => BudgetListDuplicateBottomModalWidget(
            onConfirm: (clientData, items, comments, receipts) async {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;
              final loading = getIt<LoadingEventRepository>();
              try {
                await loading.alertLoading(context);
                await _vm.duplicateBudget(
                  budget,
                  clientData: clientData,
                  items: items,
                  comments: comments,
                  receipts: receipts,
                );
              } finally {
                if (mounted) loading.closeLoading(context);
              }
            },
          ),
    );
  }

  Future<void> _openReceipts(String id) async {
    final budget = await _vm.budgetForNavigation(id);
    if (budget == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptListView(item: budget)),
    );
  }

  void _handleAction(String action, ChatMessageEntity msg) async {
    if (action.startsWith(ChatAssistantViewModel.findBudgetAction)) {
      await _findBudget(
        action.substring(ChatAssistantViewModel.findBudgetAction.length),
      );
      return;
    }
    if (action == DispatchAgentToolUsecase.selectReceiptBudget) {
      await _pickBudgetForReceipts();
      return;
    }
    if (action == ChatAssistantViewModel.selectProofBudgetAction) {
      await _pickBudgetForProof();
      return;
    }
    if (action.startsWith(ChatAssistantViewModel.openProofsAction)) {
      await _openProofs(
        action.substring(ChatAssistantViewModel.openProofsAction.length),
      );
      return;
    }
    if (action == DispatchAgentToolUsecase.selectDuplicateBudget) {
      await _pickBudgetToDuplicate();
      return;
    }
    if (action.startsWith('open_budget|')) {
      await _openBudget(action.substring('open_budget|'.length));
      return;
    }
    if (action == ChatBudgetStrings.copyLinkLabel) {
      await _vm.copyLinkCommand.execute();
      if (mounted && _vm.copyLinkCommand.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ChatBudgetStrings.linkCopied),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (action == ChatBudgetStrings.generatePdfLabel) {
      await _vm.generatePdfCommand.execute();
      return;
    }
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

  /// "+" de anexos (só modo IA). `null` esconde o botão.
  final VoidCallback? onAttach;

  const _EditAwareInputBar({
    this.onAttach,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
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
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onAttach != null && !isEditing)
                  IconButton(
                    onPressed: enabled ? onAttach : null,
                    tooltip: PaymentProofStrings.attach,
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          isEditing
                              ? 'Edite a mensagem...'
                              : 'Digite uma mensagem...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF2A2D3E),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
  final TextEditingController? cepController;
  final bool isCorrecting;
  final VoidCallback onSubmit;
  final VoidCallback onCancelAndProceed;

  const _ManualAddressForm({
    required this.streetController,
    required this.numberController,
    required this.cityController,
    required this.neighborhoodController,
    this.cepController,
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
                  child: _buildField(
                    streetController,
                    ChatBudgetStrings.streetField,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _buildField(
                    numberController,
                    ChatBudgetStrings.numberField,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (isCorrecting && cepController != null) ...[
              const SizedBox(height: 8),
              _buildField(
                cepController!,
                'CEP',
                keyboardType: TextInputType.number,
              ),
            ],
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

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF2A2D3E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
