import 'package:oflite/modules/chat_assistant/domain/usecase/handle_comment_library_menu_option_usecase.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/comment_library_creator_view.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_list/comment_library_list_view.dart';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_app_bar.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_list/budget_comment_list_view.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_duplicate_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_list_items/budget_list_items_view.dart';
import 'package:oflite/modules/budget/presenter/budget_tab/budget_tab_view.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/chat_assistant_view_model.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_attachment_panel.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_edit_aware_input_bar.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_manual_address_form.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_message_bubble.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_typing_indicator.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_budget_picker/chat_budget_picker_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/chat_media_picker_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_proof_preview/chat_proof_preview_view.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/image/presenter/image_edit_view.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_list/payment_proof_list_view.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_viewer/payment_proof_viewer_view.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/modules/pdf/presenter/pdf_budget/pdf_budget_view.dart';
import 'package:oflite/modules/pdf/presenter/pdf_edit/presenter/pdf_edit_view.dart';
import 'package:oflite/modules/pdf/presenter/pdf_model_select/presenter/pdf_model_select_view.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/modules/product/presenter/product_price_list/product_price_list_view.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/receipt_list_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/form/app_keyboard_dismiss_bar.dart';

/// Tela do assistente de orçamentos (chat estilo WhatsApp).
///
/// A View só executa commands, abre telas/modais (precisam de `context`) e
/// controla scroll/foco. Toda decisão de fluxo fica na ViewModel.
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

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _scrollController.dispose();
    _inputFocusNode.removeListener(_onInputFocusChanged);
    _inputFocusNode.dispose();
    super.dispose();
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

  // ------------------------------------------------------------------
  // Scroll e foco
  // ------------------------------------------------------------------

  /// Ao focar o campo, rola até o fim depois que o teclado sobe (a área
  /// da lista encolhe durante a animação do teclado).
  void _onInputFocusChanged() {
    if (!_inputFocusNode.hasFocus) return;
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _scrollToBottom();
    });
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

  // ------------------------------------------------------------------
  // Alertas (precisam de context)
  // ------------------------------------------------------------------

  void _showProofIssue(ProofAttachmentValidation v) {
    final alert = _vm.proofIssueAlert(v);
    final msg = alert.message;
    if (msg == null || !mounted) return;
    final display = getIt<DisplayAlertRepository>();
    if (alert.isWarning) {
      display.notificationWarning(
        context,
        PaymentProofStrings.warningTitle,
        msg,
      );
    } else {
      display.notificationError(context, PaymentProofStrings.errorTitle, msg);
    }
  }

  void _showShareErrorIfAny() {
    if (_vm.shareErrorToShow == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = _vm.shareErrorToShow;
      if (!mounted || msg == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: chatErrorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _vm.clearShareError();
    });
  }

  void _showLinkCopied() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ChatAssistantStrings.linkCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Navegação: a ViewModel decide, a View abre
  // ------------------------------------------------------------------

  Future<void> _onButtonAction(ChatMessageEntity msg, String action) async {
    final nav = await _vm.onButtonAction(msg, action);
    if (nav == null || !mounted) return;
    if (nav.startsWith(ChatAssistantViewModel.openProofsAction)) {
      return _openProofs(
        nav.substring(ChatAssistantViewModel.openProofsAction.length),
      );
    }
    switch (nav) {
      case ChatAssistantViewModel.linkCopiedNav:
        return _showLinkCopied();
      case ChatAssistantViewModel.openProductsNav:
        return _openBudgetItems();
      case ChatAssistantViewModel.openCommentsNav:
        return _openComments();
      case ChatAssistantViewModel.openExistingCommentsNav:
        return _openExistingBudgetComments();
    }
    await _navigate(nav);
  }

  /// Navegação pendente disparada pela ViewModel (fora do build).
  Future<void> _handlePendingNavigation() async {
    final nav = _vm.pendingNavigation;
    if (nav == null) return;
    // Limpa imediatamente para evitar re-executar no próximo build
    _vm.clearPendingNavigation();
    await _navigate(nav);
  }

  Future<void> _navigate(String nav) async {
    if (nav.startsWith('open_budget|')) {
      return _openBudget(nav.substring('open_budget|'.length));
    }
    if (nav.startsWith(ChatAssistantViewModel.findBudgetAction)) {
      return _findBudget(
        nav.substring(ChatAssistantViewModel.findBudgetAction.length),
      );
    }
    switch (nav) {
      case ChatAssistantViewModel.openBudgetPdfAction:
        await _push(const PdfBudgetView());
        _vm.onBudgetPdfClosed();
      case DispatchAgentToolUsecase.selectReceiptBudget:
        await _pickBudgetForReceipts();
      case ChatAssistantViewModel.selectProofBudgetAction:
        await _pickBudgetForProof();
      case DispatchAgentToolUsecase.selectDuplicateBudget:
        await _pickBudgetToDuplicate();
      case DispatchAgentToolUsecase.selectCommentBudget:
        await _pickBudgetToComment();
      case 'open_price_list':
        await _push(const ProductPriceListView());
        if (mounted) await _vm.resetChatCommand.execute();
      case 'open_product_creator':
        _openProductCreator();
      case HandleCommentLibraryMenuOptionUsecase.openListNav:
        await _push(const CommentLibraryListView());
        if (mounted) await _vm.repeatCurrentMenu();
      case HandleCommentLibraryMenuOptionUsecase.openCreatorNav:
        final saved = await showCommentLibraryCreatorBottomModal(context);
        if (mounted) await _vm.onCommentCreatorClosed(saved?.name);
      case 'open_pdf_edit':
        _push(const PdfEditView());
      case 'open_change_name':
        _openChangeNameModal();
      case ChatAssistantViewModel.openLogoEditNav:
        await _openLogoEditFlow();
      case 'open_pdf_model_select':
        final result = await _push(const PdfModelSelectView());
        if (mounted) await _vm.onPdfModelSelectClosed(result == true);
    }
  }

  Future<Object?> _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  /// Abre a tela de itens do orçamento (edita/exclui/adiciona itens).
  Future<void> _openBudgetItems() async {
    final budget = _vm.draftBudget;
    if (budget == null) return;
    await _push(BudgetListItemsView(item: budget));
    // Ao voltar, os itens já foram salvos: segue para os comentários.
    await _vm.goToCommentsAfterProductEdit();
  }

  Future<void> _openComments() async {
    final budget = _vm.draftBudget;
    if (budget == null) return;
    await _push(BudgetCommentListView(item: budget));
    // Ao voltar da tela de comentários, finaliza o orçamento
    await _vm.finalizeAfterComments();
  }

  /// IA: escolhe o orçamento no modal e pergunta se quer comentar.
  Future<void> _pickBudgetToComment() async {
    final id = await ChatBudgetPickerView.show(context);
    if (id == null || !mounted) return;
    final budget = await _vm.budgetForNavigation(id);
    if (budget == null || !mounted) return;
    await _vm.askCommentsForBudget(budget);
  }

  /// Tela de comentários do orçamento escolhido (fluxo da IA).
  Future<void> _openExistingBudgetComments() async {
    final budget = _vm.commentBudget;
    if (budget == null) return;
    await _push(BudgetCommentListView(item: budget));
    if (mounted) await _vm.onExistingBudgetCommentsClosed();
  }

  /// Abre a tela do orçamento (card da IA ou tool `open_budget`).
  Future<void> _openBudget(String id) async {
    final budget = await _vm.budgetForNavigation(id);
    if (budget == null || !mounted) return;
    await _push(BudgetTabView(item: budget));
  }

  Future<void> _openReceipts(String id) async {
    final budget = await _vm.budgetForNavigation(id);
    if (budget == null || !mounted) return;
    await _push(ReceiptListView(item: budget));
  }

  Future<void> _openProofs(String budgetId) async {
    final budget = await _vm.budgetForNavigation(budgetId);
    if (budget == null || !mounted) return;
    await _push(PaymentProofListView(item: budget));
  }

  void _openAttachment(ProofAttachment f) => PaymentProofViewerView.open(
    context,
    title: f.name,
    type: f.type,
    localPath: f.path,
  );

  /// "Encontrar orçamentos": modal já buscando [name] no banco → tela do
  /// orçamento → ao voltar, oferece abrir de novo ou voltar ao menu.
  Future<void> _findBudget(String name) async {
    final id = await ChatBudgetPickerView.show(context, initialQuery: name);
    if (id == null || !mounted) return;
    await _openBudget(id);
    if (mounted) await _vm.onFoundBudgetClosed(id);
  }

  /// Modal de seleção → lista de recibos do orçamento escolhido.
  Future<void> _pickBudgetForReceipts() async {
    final id = await ChatBudgetPickerView.show(context);
    if (id == null || !mounted) return;
    await _openReceipts(id);
  }

  Future<void> _pickBudgetForProof() async {
    final id = await ChatBudgetPickerView.show(context);
    if (!mounted) return;
    await _vm.onProofBudgetSelected(id);
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

  Future<void> _openProductCreator() async {
    final result = await showProductPriceCreatorBottomModal(
      context,
      item: ProductPriceModel(),
    );
    if (result == true || mounted) {
      await _vm.onProductCreatorClosed(result == true);
    }
  }

  Future<void> _openChangeNameModal() async {
    final newName = await getIt<DisplayAlertRepository>().dialogChangeName(
      context,
    );
    if (!mounted) return;
    await _vm.onUsernameChanged(newName);
  }

  Future<void> _openLogoEditFlow() async {
    final owner = await _vm.ownerForLogoEdit();
    if (!mounted) return;
    await _push(
      owner == null
          ? const SubscriptionView()
          : ImageEditView(
            owner: owner,
            title: ChatAssistantStrings.editLogoTitle,
          ),
    );
    if (!mounted) return;
    // Ao voltar, mostra a logo e reapresenta o menu da logo (igual a "Ver logo")
    await _vm.onLogoUpdated();
  }

  // ------------------------------------------------------------------
  // Comprovantes (§15 do CHAT_AI_AGENT_PLAN)
  // ------------------------------------------------------------------

  /// Arquivos vindos da folha de compartilhamento → prévia → chat.
  Future<void> _consumeSharedProof() async {
    // Checa antes de retirar: um chat já descartado (geração anterior) não
    // pode consumir o pendente, senão o chat novo recebe null.
    if (!mounted) return;
    final shared = _vm.takeSharedProof();
    if (shared == null) return;
    await _previewAndSend(shared, origin: PaymentProofOrigin.share);
  }

  Future<void> _previewAndSend(
    ProofAttachmentValidation? v, {
    PaymentProofOrigin origin = PaymentProofOrigin.chat,
  }) async {
    if (v == null || !mounted) return;
    _showProofIssue(v);
    if (!_vm.canPreviewProof(v)) return;
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
        if (!await _vm.canUseMedia(camera: true) || !mounted) return;
        await _previewAndSend(await _vm.captureProofPhoto());
      case ChatAttachmentChoice.document:
        await _previewAndSend(await _vm.pickProofDocument());
      case null:
        break;
    }
  }

  Future<void> _attachPhotos() async {
    // Android: Photo Picker do sistema (política do Play, sem READ_MEDIA_*).
    if (Platform.isAndroid) {
      await _previewAndSend(await _vm.pickSystemPhotos());
      return;
    }
    if (!await _vm.canUseMedia(camera: false) || !mounted) return;
    final result = await ChatMediaPickerView.show(context);
    if (result == null || !mounted) return;
    _showProofIssue(result.validation);
    if (!result.validation.isValid) return;
    await _vm.sendProofAttachments(result.validation.files, result.caption);
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    _scrollToBottom();
    // Processa navegação pendente da ViewModel (fora do build)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _handlePendingNavigation();
    });
    _showShareErrorIfAny();

    return Scaffold(
      backgroundColor: chatBackgroundColor,
      appBar: ChatAppBar(onRestart: () => _vm.resetChatCommand.execute()),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          AppKeyboardDismissBar(label: ChatAssistantStrings.closeKeyboard),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _vm.messages.length + (_vm.isAiThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _vm.messages.length) return const ChatTypingIndicator();
        final msg = _vm.messages[index];
        return ChatMessageBubble(
          message: msg,
          onAction: (action) => _onButtonAction(msg, action),
          buttonsEnabled: _vm.isButtonsActive(msg),
          onOpenAttachment: _openAttachment,
          onOptionSelect: (value, label) => _vm.selectOption(msg, value, label),
          onEditMessage: _vm.prepareEditMessage,
        );
      },
    );
  }

  Widget _buildInputArea() {
    if (_vm.showManualAddressForm) {
      return ChatManualAddressForm(
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
    return ChatEditAwareInputBar(
      onAttach: _vm.canAttach ? _openAttachPanel : null,
      controller: _vm.textController,
      focusNode: _inputFocusNode,
      isEditing: _vm.isEditingMessage,
      onCancelEdit: _vm.cancelEdit,
      enabled: _vm.inputEnabled,
      onSend: _vm.submitInput,
    );
  }
}
