import 'dart:async';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/duplicate_budget_usecase.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as user_info;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_script_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/check_ai_access_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/confirm_agent_action_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/create_budget_from_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/fetch_chat_script_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_change_username_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_logo_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_main_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_pdf_edit_confirm_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_pdf_edit_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_pdf_field_input_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_price_list_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/on_logo_updated_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/reset_chat_to_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/resolve_ai_failure_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/run_agent_turn_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_find_budget_prompt_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_reports_prompt_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_pdf_edit_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_price_list_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/enum/chat_flow_step_enum.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/build_budget_final_actions_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/generate_budget_pdf_from_chat_usecase.dart';
import 'package:oflite/modules/core/cep/data/model/address.dart';
import 'package:oflite/modules/core/cep/domain/repository/cep_repository.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/pick_proof_attachments_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/receive_shared_proof_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/check_proof_limit_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/create_payment_proof_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/parse_money_input_usecase.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';

/// ViewModel do assistente de chat.
///
/// SEMPRE inicia do zero. Não restaura conversas em andamento.
/// Quando o usuário sai da tela e volta, o chat começa limpo.
class ChatAssistantViewModel extends ChangeNotifier {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;
  final CreateBudgetFromChatUsecase _usecase;
  final FetchChatScriptUsecase _fetchScriptUsecase;
  final ShowPriceListMenuUsecase _showPriceListUsecase;
  final ResetChatToMenuUsecase _resetToMenuUsecase;
  final HandleMainMenuOptionUsecase _handleMainMenuOption;
  final HandlePriceListMenuOptionUsecase _handlePriceListMenuOption;
  final HandlePdfEditMenuOptionUsecase _handlePdfEditMenuOption;
  final ShowPdfEditMenuUsecase _showPdfEditUsecase;
  final HandlePdfFieldInputUsecase _handlePdfFieldInput;
  final HandlePdfEditConfirmOptionUsecase _handlePdfEditConfirm;
  final HandleChangeUsernameOptionUsecase _handleChangeUsername;
  final HandleLogoMenuOptionUsecase _handleLogoMenuOption;
  final OnLogoUpdatedUsecase _onLogoUpdated;
  final PdfRepository _pdfRepo;
  final ChatAiRepository _aiRepo;
  final CheckAiAccessUsecase _checkAiAccess;
  final RunAgentTurnUsecase _runAgentTurn;
  final ConfirmAgentActionUsecase _confirmAgentAction;
  final ResolveAiFailureUsecase _resolveAiFailure;
  final ShowReportsPromptUsecase _showReportsPrompt;
  final DuplicateBudgetUsecase _duplicateBudget;
  final ShowFindBudgetPromptUsecase _showFindBudgetPrompt;
  final BuildBudgetFinalActionsUsecase _buildFinalActions;
  final GenerateBudgetPdfFromChatUsecase _generatePdf;
  final CheckProofLimitUsecase _checkProofLimit;
  final CreatePaymentProofUsecase _createProof;
  final ParseMoneyInputUsecase _parseMoney;
  final PickProofAttachmentsUsecase _pickProof;
  final ReceiveSharedProofUsecase _receiveShared;

  bool _disposed = false;

  ChatAssistantViewModel(
    this._chatRepo,
    this._scriptRepo,
    this._usecase,
    this._fetchScriptUsecase,
    this._showPriceListUsecase,
    this._resetToMenuUsecase,
    this._handleMainMenuOption,
    this._handlePriceListMenuOption,
    this._handlePdfEditMenuOption,
    this._showPdfEditUsecase,
    this._handlePdfFieldInput,
    this._handlePdfEditConfirm,
    this._handleChangeUsername,
    this._handleLogoMenuOption,
    this._onLogoUpdated,
    this._pdfRepo,
    this._aiRepo,
    this._checkAiAccess,
    this._runAgentTurn,
    this._confirmAgentAction,
    this._resolveAiFailure,
    this._showReportsPrompt,
    this._duplicateBudget,
    this._showFindBudgetPrompt,
    this._buildFinalActions,
    this._generatePdf,
    this._checkProofLimit,
    this._createProof,
    this._parseMoney,
    this._pickProof,
    this._receiveShared,
  ) {
    _chatRepo.addListener(_onRepoChanged);
    _scriptRepo.addListener(_onRepoChanged);
    shareLinkCommand.addListener(_onCommandDone);
    copyLinkCommand.addListener(_onCommandDone);
    generatePdfCommand.addListener(_onCommandDone);
  }

  /// Navegação para a tela de PDF do orçamento criado no chat.
  static const openBudgetPdfAction = 'open_budget_pdf';

  ChatFlowStep _step = ChatFlowStep.idle;

  ChatFlowStep get step => _step;

  void _setStep(ChatFlowStep value) {
    _step = value;
    _chatRepo.setCurrentFlowStep(value.name);
  }

  void _setStepFromName(String name) {
    _step = _nameToStep(name);
    _chatRepo.setCurrentFlowStep(name);
  }

  ChatFlowStep _nameToStep(String name) {
    return ChatFlowStep.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ChatFlowStep.mainMenu,
    );
  }

  List<ChatMessageEntity> get messages => _chatRepo.messages;

  /// Assinante: texto livre no menu principal vai para a IA.
  /// Decidido uma vez por sessão no [_initialize].
  bool _aiMode = false;

  bool get aiMode => _aiMode;

  /// IA processando (modelo ou ação confirmada) → View mostra "digitando…".
  bool _isAiThinking = false;

  bool get isAiThinking => _isAiThinking;

  /// Falhas seguidas da IA nesta sessão (zera a cada resposta boa).
  int _aiFailures = 0;

  void _setAiThinking(bool value) {
    _isAiThinking = value;
    if (!_disposed) notifyListeners();
  }

  /// Escrita preparada pela IA aguardando "Confirmar"/"Cancelar".
  AgentPendingAction? _pendingAgentAction;

  /// Opções numéricas do menu principal (seguem o fluxo determinístico).
  static const _mainMenuOptions = {'1', '2', '3', '4'};

  /// Opção "Relatórios" do menu (só existe no modo IA).
  static const _reportsOption = '5';

  /// Opção "Encontrar orçamentos" do menu (só existe no modo IA).
  static const _findBudgetOption = '6';

  /// Ação/navegação que abre o modal de orçamentos já buscando o nome.
  static const findBudgetAction = 'find_budget|';

  CustomerInfo? get draftBudget => _chatRepo.draftBudget;

  ChatScriptEntity? get _script => _scriptRepo.currentScript;

  bool get isLoading => initializeChat.running || sendTextCommand.running;

  String? get shareErrorMessage => _shareErrorMessage;
  String? _shareErrorMessage;

  final textController = TextEditingController();
  final cepController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final cityController = TextEditingController();
  final neighborhoodController = TextEditingController();

  bool _isCorrectingAddress = false;

  bool get isCorrectingAddress => _isCorrectingAddress;

  bool _isPdfEditAddressMode = false;

  String _pendingClientName = '';
  String _pendingPhone = '';

  String? _clientNameMsgId;
  String? _clientPhoneMsgId;

  String? _editingMsgId;
  String? _editingField;

  bool get isEditingMessage => _editingMsgId != null;

  String? _reviewMsgId;
  String? _commentQuestionMsgId;

  String? _commentsFeedbackMsgId;

  Address? _pendingAddress;

  final List<ItemsBudget> _currentDraftItems = [];

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String? _pdfEditField;

  String? _pendingNavigation;

  String? get pendingNavigation => _pendingNavigation;

  void clearPendingNavigation() {
    _pendingNavigation = null;
  }

  late final Command0<void> initializeChat = Command0(_initialize);
  late final Command1<void, String> sendTextCommand = Command1(_sendText);
  late final Command1<void, ChatOptionTap> selectOptionCommand = Command1(
    _selectOption,
  );
  late final Command0<void> pickContactCommand = Command0(_pickContact);
  late final Command0<void> createDraftCommand = Command0(_createDraftFromName);
  late final Command0<void> skipAddressCommand = Command0(_skipAddress);
  late final Command1<void, String> submitCepCommand = Command1(_submitCep);
  late final Command0<void> confirmCepAddressCommand = Command0(
    _confirmCepAddress,
  );
  late final Command0<void> submitManualAddressCommand = Command0(
    _submitManualAddress,
  );
  late final Command0<void> openProductSelectionCommand = Command0(_noop);
  late final Command1<void, List<ItemsBudget>> confirmProductsCommand =
      Command1(_confirmProducts);
  late final Command1<void, List<ItemsBudget>> editProductsCommand = Command1(
    _editProducts,
  );
  late final Command0<void> shareLinkCommand = Command0(_shareLink);
  late final Command0<void> copyLinkCommand = Command0(_copyLink);
  late final Command0<void> generatePdfCommand = Command0(_generateBudgetPdf);
  late final Command0<void> resetChatCommand = Command0(_resetChat);

  // ------------------------------------------------------------------
  // Inicialização
  // ------------------------------------------------------------------
  Future<Result<void>> _initialize() async {
    _clearLocalState();
    _aiMode = _checkAiAccess();
    _aiFailures = 0;
    // Pré-carrega o intersticial do "compartilhar link" (ignorado p/ assinante)
    getIt<AdsRepository>().loadInterstitial();
    try {
      await _fetchScriptUsecase.call();
    } catch (_) {}
    final step = await _resetToMenuUsecase(withReports: _aiMode);
    _setStepFromName(step);
    notifyListeners();
    return Result.ok(null);
  }

  Future<void> _backToMainMenu() async {
    _clearLocalState();
    final step = await _resetToMenuUsecase(withReports: _aiMode);
    _setStepFromName(step);
    notifyListeners();
  }

  void _clearLocalState() {
    _usedButtonMsgIds.clear();
    _chatRepo.clearSession();
    _chatRepo.setCurrentFlowStep(null);
    _currentDraftItems.clear();
    _pendingClientName = '';
    _pendingPhone = '';
    _pendingAddress = null;
    _isCorrectingAddress = false;
    _shareErrorMessage = null;
    textController.clear();
    cepController.clear();
    streetController.clear();
    numberController.clear();
    cityController.clear();
    neighborhoodController.clear();
    _clientNameMsgId = null;
    _clientPhoneMsgId = null;
    _editingMsgId = null;
    _editingField = null;
    _reviewMsgId = null;
    _commentQuestionMsgId = null;
    _commentsFeedbackMsgId = null;
    _commentBudget = null;
    _pdfEditField = null;
    _pendingNavigation = null;
    _isPdfEditAddressMode = false;
    _aiRepo.clearHistory();
    _pendingAgentAction = null;
    _clearProofDraft();
  }

  // ------------------------------------------------------------------
  // Validação de telefone
  // ------------------------------------------------------------------
  bool _isValidPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 11;
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return _phoneMask.maskText(digits);
  }

  String? _tryFormatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) return null;
    return _phoneMask.maskText(digits);
  }

  // ------------------------------------------------------------------
  // Toque em botão de opção (ChatMessageType.optionList)
  // ------------------------------------------------------------------

  // ------------------------------------------------------------------
  // Botões ativos x desativados (ficam opacos após uso)
  // ------------------------------------------------------------------

  /// Mensagens cujos botões já foram tocados.
  final Set<String> _usedButtonMsgIds = {};

  /// Ações que abrem tela/modal/picker que o usuário pode cancelar —
  /// continuam ativas após o toque e só desativam quando a conversa avança.
  static const _repeatableActions = {
    'pick_contact',
    'open_products',
    'edit_products',
    'edit_comments',
    'Editar comentários',
    'share_link',
    'open_logo_edit',
  };

  /// Chamado pela View a cada toque em botão de mensagem.
  void markButtonUsed(ChatMessageEntity msg, String action) {
    if (_repeatableActions.contains(action) || _isAiRepeatable(action)) return;
    _usedButtonMsgIds.add(msg.id);
    notifyListeners();
  }

  /// Define se os botões de [msg] estão ativos.
  ///
  /// Inativo após o toque ou quando chega outra mensagem com botões.
  /// - `optionList`: também só fica ativo no step do menu. Texto digitado
  ///   (ex: opção inválida) não desativa — o menu continua utilizável.
  /// - Demais: também desativa quando há mensagem do usuário depois dela.
  /// Cards da IA (abrir orçamento, compartilhar link) seguem clicáveis.
  bool _isAiRepeatable(String action) =>
      action.startsWith('open_budget|') ||
      action.startsWith('share_url|') ||
      action.startsWith(findBudgetAction) ||
      action == DispatchAgentToolUsecase.selectReceiptBudget ||
      action == DispatchAgentToolUsecase.selectDuplicateBudget ||
      action == DispatchAgentToolUsecase.selectCommentBudget ||
      action == selectProofBudgetAction ||
      action.startsWith(openProofsAction);

  bool isButtonsActive(ChatMessageEntity msg) {
    if (msg.type == ChatMessageType.budgetList ||
        msg.type == ChatMessageType.receiptsReportCard ||
        _isAiRepeatable(msg.payload?['action'] as String? ?? '')) {
      return true;
    }
    final isOptionList = msg.type == ChatMessageType.optionList;
    if (isOptionList && msg.payload?['optionsStep'] != _step.name) {
      return false;
    }
    if (_usedButtonMsgIds.contains(msg.id)) return false;
    final list = _chatRepo.messages;
    final index = list.indexOf(msg);
    if (index < 0) return false;
    for (final later in list.skip(index + 1)) {
      if (_hasButtons(later)) return false;
      if (!isOptionList && later.sender == ChatSender.user) return false;
    }
    return true;
  }

  /// Reenvia o menu do step atual quando o usuário volta de uma tela
  /// sem concluir (ex: cancelou o cadastro de produto) — o menu tocado
  /// já ficou opaco.
  Future<void> repeatCurrentMenu() async {
    String? step;
    if (_step == ChatFlowStep.priceListMenu) {
      step = await _showPriceListUsecase();
    } else if (_step == ChatFlowStep.pdfEditMenu) {
      step = await _showPdfEditUsecase();
    }
    if (step == null) return;
    _setStepFromName(step);
    notifyListeners();
  }

  bool _hasButtons(ChatMessageEntity msg) => switch (msg.type) {
    ChatMessageType.text => false,
    ChatMessageType.attachment => false,
    ChatMessageType.image => msg.payload?['changeAction'] != null,
    _ => true,
  };

  /// Envia o `value` da opção pelo mesmo caminho do texto digitado,
  /// exibindo o `label` na bolha do usuário.
  Future<Result<void>> _selectOption(ChatOptionTap option) async {
    if (option.step != _step.name) return Result.ok(null); // menu antigo
    return _sendText(option.value, displayText: option.label);
  }

  // ------------------------------------------------------------------
  // Envia texto do usuário
  // ------------------------------------------------------------------
  Future<Result<void>> _sendText(String text, {String? displayText}) async {
    if (text.trim().isEmpty) return Result.ok(null);
    final clean = text.trim();

    // Em qualquer fluxo, "0" volta ao menu principal
    if (clean == '0' && _step != ChatFlowStep.mainMenu) {
      if (displayText != null) {
        await _sendUserMessageWithId(_generateMessageId(), displayText);
      }
      await _backToMainMenu();
      return Result.ok(null);
    }

    // Texto livre após "Comprovante salvo": volta a valer o menu principal.
    if (_step == ChatFlowStep.proofDone) _setStep(ChatFlowStep.mainMenu);

    // Modo edição
    if (_editingMsgId != null && _editingField != null) {
      await _chatRepo.updateMessage(_editingMsgId!, clean);
      if (_editingField == 'clientName') {
        _pendingClientName = clean;
      } else if (_editingField == 'clientPhone') {
        final formatted = _tryFormatPhone(clean);
        _pendingPhone = formatted ?? clean;
      }
      textController.clear();
      _editingMsgId = null;
      _editingField = null;
      notifyListeners();
      return Result.ok(null);
    }

    // Envia mensagem do usuário
    final msgId = _generateMessageId();
    final userPayload = switch (_step) {
      ChatFlowStep.askClient => {'editableField': 'clientName'},
      ChatFlowStep.askPhone => {'editableField': 'clientPhone'},
      _ => null,
    };
    await _sendUserMessageWithId(
      msgId,
      displayText ?? clean,
      payload: userPayload,
    );

    if (_step == ChatFlowStep.askClient) {
      _clientNameMsgId = msgId;
    } else if (_step == ChatFlowStep.askPhone) {
      _clientPhoneMsgId = msgId;
    }

    try {
      if (_isProofStep) {
        await _handleProofText(clean);
      } else if (_step == ChatFlowStep.mainMenu &&
          _aiMode &&
          clean == _reportsOption) {
        _setStepFromName(await _showReportsPrompt());
        notifyListeners();
      } else if (_step == ChatFlowStep.mainMenu &&
          _aiMode &&
          clean == _findBudgetOption) {
        _setStepFromName(await _showFindBudgetPrompt());
        notifyListeners();
      } else if (_step == ChatFlowStep.findBudgetAskName) {
        await _findBudget(clean);
      } else if (_step == ChatFlowStep.mainMenu &&
          _aiMode &&
          !_mainMenuOptions.contains(clean)) {
        await _handleAiMessage(clean);
      } else if (_step == ChatFlowStep.mainMenu) {
        await _handleMainMenu(clean);
      } else if (_step == ChatFlowStep.priceListMenu) {
        await _handlePriceList(clean);
      } else if (_step == ChatFlowStep.pdfEditConfirmEntry) {
        await _handlePdfEditConfirmEntry(clean);
      } else if (_step == ChatFlowStep.pdfEditMenu) {
        await _handlePdfEdit(clean);
      } else if (_step == ChatFlowStep.pdfEditFieldInput) {
        await _handlePdfField(clean);
      } else if (_step == ChatFlowStep.pdfEditConfirm) {
        await _handlePdfConfirm(clean);
      } else if (_step == ChatFlowStep.changeUsername) {
        await _handleUsername(clean);
      } else if (_step == ChatFlowStep.changeUsernameResult) {
        await _handleUsernameResult(clean);
      } else if (_step == ChatFlowStep.logoMenu) {
        await _handleLogo(clean);
      } else if (_step == ChatFlowStep.welcome ||
          _step == ChatFlowStep.askClient) {
        _pendingClientName = clean;
        _setStep(ChatFlowStep.askPhone);
        await _addBotMessage(
          _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
          type: ChatMessageType.text,
        );
      } else if (_step == ChatFlowStep.askPhone) {
        if (!_isValidPhone(clean)) {
          await _addBotMessage(
            ChatAssistantStrings.invalidPhone,
            type: ChatMessageType.text,
          );
        } else {
          _pendingPhone = _normalizePhone(clean);
          await _showClientDataConfirmation();
        }
      } else if (_step == ChatFlowStep.askHasCep) {
        if (clean == '1') {
          await _askForCep();
        } else if (clean == '2') {
          await _goToManualAddress();
        } else {
          await _addBotMessage(
            ChatAssistantStrings.menuInvalidOption,
            type: ChatMessageType.text,
          );
        }
      } else if (_step == ChatFlowStep.askCep) {
        await _submitCep(clean);
      }
    } catch (e) {
      await _addBotMessage(
        ChatAssistantStrings.processingError(e),
        type: ChatMessageType.text,
      );
    }
    return Result.ok(null);
  }

  // ------------------------------------------------------------------
  // Handlers de menus delegando para UseCases
  // ------------------------------------------------------------------
  /// Texto livre do assinante. Em falha (rede, cota, resposta vazia) mostra
  /// o fallback — o menu acima continua ativo, o usuário nunca fica travado.
  Future<void> _handleAiMessage(String text) async {
    _pendingAgentAction = null; // nova mensagem descarta confirmação antiga
    _setAiThinking(true);
    Result<AgentTurnResult> result;
    try {
      // Teto do turno inteiro (modelo + consultas das tools): nunca trava.
      result = await _runAgentTurn(text).timeout(const Duration(seconds: 45));
    } catch (e) {
      // Qualquer exceção inesperada conta como falha da IA (nunca trava).
      result = Result.error(e is Exception ? e : Exception('$e'));
    } finally {
      _setAiThinking(false);
    }
    if (result case Error(:final error)) {
      await _onAiFailure(error);
      return;
    }
    _aiFailures = 0;
    final turn = (result as Ok<AgentTurnResult>).value;

    if (turn.menuOption != null) {
      // Handoff: abre o mesmo fluxo da opção do menu.
      await _handleMainMenu(turn.menuOption!);
      return;
    }
    if (turn.pending != null) {
      for (final card in turn.messages) {
        await _chatRepo.sendMessage(card);
      }
      _pendingAgentAction = turn.pending;
      await _addBotMessage(
        turn.text,
        type: ChatMessageType.inlineButtons,
        payload: {
          'actions': [
            ChatAssistantStrings.aiConfirmLabel,
            ChatAssistantStrings.aiCancelLabel,
          ],
        },
      );
      return;
    }
    if (turn.text.isNotEmpty) {
      await _addBotMessage(turn.text, type: ChatMessageType.text);
    }
    for (final card in turn.messages) {
      await _chatRepo.sendMessage(card);
    }
    if (turn.navigation != null) {
      _pendingNavigation = turn.navigation;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Comprovantes de pagamento (§15 do CHAT_AI_AGENT_PLAN) — sem LLM (R8).
  // Toda mensagem do bot no fluxo tem "Voltar ao menu" (R10): o botão envia
  // "0", que descarta o rascunho em [_backToMainMenu].
  // ------------------------------------------------------------------

  /// Ação/navegação que abre o modal de orçamentos para o comprovante.
  static const selectProofBudgetAction = 'proof_select_budget';

  /// Ação que abre a lista de comprovantes: `open_proofs|{budgetId}`.
  static const openProofsAction = 'open_proofs|';

  List<ProofAttachment> _proofFiles = [];
  String? _proofComment;
  double? _proofValue;
  String? _proofBudgetId;
  String? _proofName;
  PaymentProofOrigin _proofOrigin = PaymentProofOrigin.chat;

  bool get _isProofStep => switch (_step) {
    ChatFlowStep.proofSelectBudget ||
    ChatFlowStep.proofAskName ||
    ChatFlowStep.proofAskValue ||
    ChatFlowStep.proofSaving ||
    ChatFlowStep.proofSaveError => true,
    _ => false,
  };

  /// O "+" só aparece no modo IA (R1) e fora de outros fluxos.
  bool get canAttach =>
      _aiMode &&
      (_step == ChatFlowStep.mainMenu ||
          _step == ChatFlowStep.idle ||
          _step == ChatFlowStep.proofDone);

  bool get isSavingProof => _step == ChatFlowStep.proofSaving;

  /// Câmera/fotos liberadas? `null` = ainda não perguntado.
  ({bool camera, bool gallery})? _mediaPermissions;

  /// View mostra o snack "Não consigo seguir sem liberação da permissão."
  bool _mediaPermissionDenied = false;

  bool get mediaPermissionDenied => _mediaPermissionDenied;

  void consumeMediaPermissionDenied() => _mediaPermissionDenied = false;

  /// Pede câmera + fotos ao abrir o chat (só modo IA). Alguma recusada →
  /// snack. Não bloqueia o "+": cada opção confere a sua com [canUseMedia].
  Future<void> ensureMediaPermissions() async {
    if (!_aiMode) return;
    final p = await _pickProof.requestPermissions();
    _mediaPermissions = p;
    if (!p.camera || !p.gallery) {
      _mediaPermissionDenied = true;
      notifyListeners();
    }
  }

  /// Confere (e pede de novo, se preciso) a permissão da opção escolhida.
  /// Recusada → snack e `false`.
  Future<bool> canUseMedia({required bool camera}) async {
    bool ok(({bool camera, bool gallery}) p) => camera ? p.camera : p.gallery;
    final cached = _mediaPermissions;
    if (cached != null && ok(cached)) return true;
    final p = await _pickProof.requestPermissions();
    _mediaPermissions = p;
    if (ok(p)) return true;
    _mediaPermissionDenied = true;
    notifyListeners();
    return false;
  }

  Future<ProofAttachment> cropProofImage(ProofAttachment f) =>
      _pickProof.crop(f, title: PaymentProofStrings.cropTitle);

  Future<ProofAttachmentValidation?> captureProofPhoto() => _pickProof.camera();

  Future<ProofAttachmentValidation?> pickSystemPhotos() =>
      _pickProof.systemPhotos();

  Future<ProofAttachmentValidation?> pickProofDocument() =>
      _pickProof.document();

  /// Arquivos recebidos pelo compartilhamento do sistema, se houver (só
  /// assinante, ver [ReceiveSharedProofUsecase]).
  ProofAttachmentValidation? takeSharedProof() =>
      _aiMode ? _receiveShared.takePending() : null;

  /// Compartilhamento recebido no meio de outro fluxo: abandona o fluxo
  /// (sem apagar a conversa) e segue para o comprovante.
  void _clearLocalStateKeepingMessages() {
    _pendingAgentAction = null;
    _pendingNavigation = null;
    _editingMsgId = null;
    _editingField = null;
    _setStep(ChatFlowStep.mainMenu);
  }

  void _clearProofDraft() {
    _proofFiles = [];
    _proofComment = null;
    _proofValue = null;
    _proofBudgetId = null;
    _proofName = null;
    _proofOrigin = PaymentProofOrigin.chat;
  }

  /// Usuário enviou 1–2 imagens ou 1 PDF (painel "+" ou compartilhamento).
  /// A legenda só com valor vira o valor; qualquer outro texto, comentário.
  Future<void> sendProofAttachments(
    List<ProofAttachment> files,
    String caption, {
    PaymentProofOrigin origin = PaymentProofOrigin.chat,
  }) async {
    if (!_aiMode || files.isEmpty) return;
    if (_step != ChatFlowStep.mainMenu && _step != ChatFlowStep.idle) {
      _clearLocalStateKeepingMessages();
    }
    _clearProofDraft();
    _proofFiles = files;
    _proofOrigin = origin;
    final text = caption.trim();
    // Legenda = nome e/ou valor (ex.: "Pix entrada R$ 500"): não pergunta
    // de novo o que já veio junto com o arquivo.
    final parsed = _parseMoney.caption(text);
    _proofName = parsed.name;
    _proofValue = parsed.value;

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: _generateMessageId(),
        sender: ChatSender.user,
        type: ChatMessageType.attachment,
        content: text,
        payload: {
          'files': [for (final f in files) f.toPayload()],
          'caption': text,
        },
        timestamp: DateTime.now(),
      ),
    );
    await _askProofBudget(PaymentProofStrings.askBudget);
  }

  Future<void> _askProofBudget(String message) async {
    _setStep(ChatFlowStep.proofSelectBudget);
    await _addBotMessage(
      message,
      type: ChatMessageType.action,
      payload: {
        'label': PaymentProofStrings.selectBudgetLabel,
        'action': selectProofBudgetAction,
        'backLabel': ChatAssistantStrings.menuBackLabel,
      },
    );
    _pendingNavigation = selectProofBudgetAction;
    notifyListeners();
  }

  /// Volta do modal de orçamentos. `null` = fechou sem escolher: o botão
  /// "Selecionar orçamento" continua ativo para tentar de novo.
  Future<void> onProofBudgetSelected(String? budgetId) async {
    if (budgetId == null || _step != ChatFlowStep.proofSelectBudget) return;
    await _sendUserMessageWithId(
      _generateMessageId(),
      PaymentProofStrings.budgetChosen(budgetId),
    );

    final limit = await _checkProofLimit(budgetId, adding: _proofFiles.length);
    switch (limit) {
      case Error():
        await _showProofSaveError();
        return;
      case Ok(:final value) when !value.fits:
        _setStep(ChatFlowStep.proofSelectBudget);
        await _chatRepo.sendMessage(
          ChatMessageEntity.botOptions(
            content:
                value.count >= 15
                    ? PaymentProofStrings.limitReached
                    : PaymentProofStrings.limitWouldExceed(value.count),
            labels: [PaymentProofStrings.chooseAnother],
            backLabel: ChatAssistantStrings.menuBackLabel,
            step: ChatFlowStep.proofSelectBudget.name,
          ),
        );
        notifyListeners();
        return;
      case Ok():
        break;
    }
    _proofBudgetId = budgetId;
    await _askNextProofField();
  }

  /// Pergunta o que falta (nome → valor) ou salva. Os dois são obrigatórios.
  Future<void> _askNextProofField() async {
    if (_proofName == null || _proofName!.isEmpty) {
      await _askProofName(PaymentProofStrings.askName);
    } else if (_proofValue == null) {
      await _askProofValue(PaymentProofStrings.askValue);
    } else {
      await _saveProof();
    }
  }

  Future<void> _askProofName(String message) async {
    _setStep(ChatFlowStep.proofAskName);
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: message,
        labels: const [],
        backLabel: ChatAssistantStrings.menuBackLabel,
        step: ChatFlowStep.proofAskName.name,
      ),
    );
    notifyListeners();
  }

  Future<void> _askProofValue(String message) async {
    _setStep(ChatFlowStep.proofAskValue);
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: message,
        labels: const [],
        backLabel: ChatAssistantStrings.menuBackLabel,
        step: ChatFlowStep.proofAskValue.name,
      ),
    );
    notifyListeners();
  }

  Future<void> _handleProofText(String text) async {
    switch (_step) {
      case ChatFlowStep.proofSelectBudget:
        // "Escolher outro orçamento" (1) ou texto qualquer → reabre o modal.
        _pendingNavigation = selectProofBudgetAction;
        notifyListeners();
      case ChatFlowStep.proofAskName:
        if (text.trim().isEmpty) {
          await _askProofName(PaymentProofStrings.nameRequired);
          return;
        }
        _proofName = text.trim();
        await _askNextProofField();
      case ChatFlowStep.proofAskValue:
        final value = _parseMoney(text);
        if (value == null) {
          await _askProofValue(PaymentProofStrings.invalidValue);
          return;
        }
        _proofValue = value;
        await _saveProof();
      case ChatFlowStep.proofSaveError:
        if (text.trim() == '1') await _saveProof();
      default:
        break;
    }
  }

  Future<void> _saveProof() async {
    final budgetId = _proofBudgetId;
    final name = _proofName;
    if (budgetId == null || name == null) return;
    _setStep(ChatFlowStep.proofSaving);
    _setAiThinking(true);
    final result = await _createProof(
      budgetId: budgetId,
      files: _proofFiles,
      name: name,
      value: _proofValue,
      comment: _proofComment,
      origin: _proofOrigin,
    );
    _setAiThinking(false);
    switch (result) {
      case Ok():
        _clearProofDraft();
        _setStep(ChatFlowStep.proofDone);
        await _addBotMessage(
          PaymentProofStrings.saved,
          type: ChatMessageType.action,
          payload: {
            'label': PaymentProofStrings.seeProofs,
            'action': '$openProofsAction$budgetId',
            'backLabel': ChatAssistantStrings.menuBackLabel,
          },
        );
      case Error(:final error) when error is PaymentProofLimitReached:
        _proofBudgetId = null;
        await _askProofBudget(PaymentProofStrings.limitReached);
      case Error():
        await _showProofSaveError();
    }
    notifyListeners();
  }

  Future<void> _showProofSaveError() async {
    _setStep(ChatFlowStep.proofSaveError);
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: PaymentProofStrings.saveError,
        labels: [PaymentProofStrings.tryAgain],
        backLabel: ChatAssistantStrings.menuBackLabel,
        step: ChatFlowStep.proofSaveError.name,
      ),
    );
    notifyListeners();
  }

  /// "Encontrar orçamentos": deixa no chat o botão para reabrir o modal e já
  /// abre o modal buscando [name] no banco. Volta ao step do menu (modo IA).
  Future<void> _findBudget(String name) async {
    final action = '$findBudgetAction$name';
    _setStep(ChatFlowStep.mainMenu);
    await _addBotMessage(
      ChatAssistantStrings.findBudgetSelect(name),
      type: ChatMessageType.action,
      payload: {
        'label': ChatAssistantStrings.aiSelectBudgetLabel,
        'action': action,
        'backLabel': ChatAssistantStrings.menuBackLabel,
      },
    );
    _pendingNavigation = action;
    notifyListeners();
  }

  /// Ao voltar da tela do orçamento encontrado: oferece abrir de novo ou
  /// voltar ao menu.
  Future<void> onFoundBudgetClosed(String id) async {
    await _addBotMessage(
      ChatAssistantStrings.findBudgetReopenQuestion,
      type: ChatMessageType.action,
      payload: {
        'label': ChatAssistantStrings.findBudgetReopenLabel,
        'action': 'open_budget|$id',
        'backLabel': ChatAssistantStrings.menuBackLabel,
      },
    );
    notifyListeners();
  }

  /// Duplica [budget] com as opções do modal (mesmo fluxo da lista de
  /// orçamentos) e confirma no chat.
  Future<void> duplicateBudget(
    CustomerInfo budget, {
    required bool clientData,
    required bool items,
    required bool comments,
    required bool receipts,
  }) async {
    final result = await _duplicateBudget(
      sourceId: budget.id!,
      copyClientData: clientData,
      copyItems: items,
      copyComments: comments,
      copyReceipts: receipts,
    );
    await _addBotMessage(switch (result) {
      Ok() => ChatAssistantStrings.aiBudgetDuplicated(
        budget.customerName ?? '',
      ),
      Error() => ChatAssistantStrings.aiBudgetDuplicateFailed,
    });
  }

  // ------------------------------------------------------------------
  // IA: comentários de um orçamento existente (list_budgets "comments")
  // ------------------------------------------------------------------

  /// Orçamento escolhido no modal para comentar.
  CustomerInfo? _commentBudget;
  CustomerInfo? get commentBudget => _commentBudget;

  /// Após escolher o orçamento no modal: pergunta se quer comentar.
  Future<void> askCommentsForBudget(CustomerInfo budget) async {
    _commentBudget = budget;
    _setStep(ChatFlowStep.askExistingBudgetComments);
    await _sendBotMessageWithId(
      _generateMessageId(),
      ChatAssistantStrings.askAddComments,
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['SIM', 'NÃO'],
      },
    );
  }

  /// Voltou da tela de comentários do orçamento existente.
  Future<void> onExistingBudgetCommentsClosed() async {
    final client = _commentBudget?.customerName ?? '';
    _commentBudget = null;
    _setStep(ChatFlowStep.mainMenu);
    await _addBotMessage(ChatAssistantStrings.aiBudgetCommentsSaved(client));
  }

  Future<void> skipExistingBudgetComments() async {
    _commentBudget = null;
    _setStep(ChatFlowStep.mainMenu);
    await _addBotMessage(ChatAssistantStrings.aiBudgetCommentsSkipped);
  }

  /// Orçamento para a View abrir a tela (card da IA / tool `open_budget`).
  Future<CustomerInfo?> budgetForNavigation(String id) async {
    final result = await getIt<BudgetRepository>().getBudgetById(id);
    return switch (result) {
      Ok(:final value) when value.id != null => value,
      _ => null,
    };
  }

  /// Rede de segurança: avisa e, se a IA seguir falhando (ou bater o limite
  /// diário), o chat continua no modo padrão — igual ao usuário free.
  Future<void> _onAiFailure(Exception error) async {
    _aiFailures++;
    final decision = _resolveAiFailure(error, consecutiveFailures: _aiFailures);
    await _addBotMessage(decision.message, type: ChatMessageType.text);
    if (!decision.fallbackToStandard) return;

    _aiMode = false;
    _pendingAgentAction = null;
    final step = await _resetToMenuUsecase(clearSession: false);
    _setStepFromName(step);
    notifyListeners();
  }

  /// Toque em Confirmar/Cancelar do card da IA. Não chama o modelo.
  Future<void> _resolveAgentAction({required bool confirmed}) async {
    final action = _pendingAgentAction;
    if (action == null) return;
    _pendingAgentAction = null;
    await _sendUserMessageWithId(
      _generateMessageId(),
      confirmed
          ? ChatAssistantStrings.aiConfirmLabel
          : ChatAssistantStrings.aiCancelLabel,
    );
    _setAiThinking(true);
    final String feedback;
    try {
      feedback = await _confirmAgentAction(action, confirmed: confirmed);
    } finally {
      _setAiThinking(false);
    }
    await _addBotMessage(feedback, type: ChatMessageType.text);
  }

  Future<void> _handleMainMenu(String option) async {
    final result = await _handleMainMenuOption(option);
    _setStepFromName(result.nextStep);
    _pendingNavigation = result.navigation;
    notifyListeners();
  }

  Future<void> _handlePriceList(String option) async {
    final result = _handlePriceListMenuOption(option);
    if (result.navigation != null) {
      _pendingNavigation = result.navigation;
    }
    if (result.nextStep != _step.name) {
      _setStepFromName(result.nextStep);
    }
    notifyListeners();
  }

  Future<void> _handlePdfEditConfirmEntry(String option) async {
    final upper = option.trim().toUpperCase();
    if (upper == 'SIM') {
      final step = await _showPdfEditUsecase();
      _setStepFromName(step);
      notifyListeners();
    } else if (upper == 'NÃO') {
      await _backToMainMenu();
    } else {
      await _addBotMessage(
        ChatAssistantStrings.menuInvalidOption,
        type: ChatMessageType.text,
      );
    }
  }

  Future<void> _handlePdfEdit(String option) async {
    final result = await _handlePdfEditMenuOption(option);
    _pdfEditField = result.pdfField;
    if (result.navigation != null) {
      _pendingNavigation = result.navigation;
    }
    if (result.nextStep == 'askHasCep') {
      _isPdfEditAddressMode = true;
    }
    _setStepFromName(result.nextStep);
    notifyListeners();
  }

  Future<void> _handlePdfField(String value) async {
    if (_pdfEditField == null) return;
    final result = await _handlePdfFieldInput(_pdfEditField!, value);
    _pdfEditField = result.pdfField;
    _setStepFromName(result.nextStep);
    notifyListeners();
  }

  Future<void> _handlePdfConfirm(String option) async {
    final result = await _handlePdfEditConfirm(option);
    if (result.nextStep == 'mainMenu') {
      await _backToMainMenu();
      return;
    }
    _setStepFromName(result.nextStep);
    notifyListeners();
  }

  Future<void> _handleUsername(String option) async {
    final result = await _handleChangeUsername(option);
    if (result.navigation != null) {
      _pendingNavigation = result.navigation;
    }
    if (result.nextStep == 'mainMenu') {
      await _backToMainMenu();
      return;
    }
    _setStepFromName(result.nextStep);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Callback da View após fechar o modal de alterar nome
  // ------------------------------------------------------------------
  Future<void> onUsernameChanged(String? newName) async {
    if (newName != null && newName.isNotEmpty) {
      await _addBotMessage(
        '${ChatAssistantStrings.changeUsernameSuccess} $newName',
        type: ChatMessageType.text,
      );
    } else {
      // Usuário cancelou ou não alterou
      await _addBotMessage(
        ChatAssistantStrings.changeUsernameNotChanged,
        type: ChatMessageType.text,
      );
    }

    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.changeUsernameRetryQuestion,
        labels: ChatAssistantStrings.changeUsernameRetryOptionLabels,
        step: ChatFlowStep.changeUsernameResult.name,
      ),
    );
    _setStep(ChatFlowStep.changeUsernameResult);
    notifyListeners();
  }

  Future<void> _handleUsernameResult(String option) async {
    switch (option) {
      case '1':
        _pendingNavigation = 'open_change_name';
        notifyListeners();
        break;
      case '2':
      case '0':
        await _backToMainMenu();
        break;
      default:
        await _addBotMessage(
          ChatAssistantStrings.menuInvalidOption,
          type: ChatMessageType.text,
        );
        break;
    }
  }

  Future<void> _handleLogo(String option) async {
    final result = await _handleLogoMenuOption(option);
    if (result.navigation != null) {
      _pendingNavigation = result.navigation;
    }
    if (result.nextStep == 'mainMenu') {
      await _backToMainMenu();
      return;
    }
    _setStepFromName(result.nextStep);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Fluxo de orçamento
  // ------------------------------------------------------------------
  Future<Result<void>> _pickContact() async {
    try {
      final permissionStatus = await user_info.FlutterContacts.permissions
          .request(user_info.PermissionType.read);
      if (permissionStatus != user_info.PermissionStatus.granted &&
          permissionStatus != user_info.PermissionStatus.limited) {
        return Result.ok(null);
      }

      final contact = await user_info.FlutterContacts.native.showPicker(
        properties: {
          user_info.ContactProperty.name,
          user_info.ContactProperty.phone,
        },
      );
      if (contact == null) return Result.ok(null);

      String name = contact.displayName?.trim() ?? '';
      if (name.isEmpty) {
        final first = contact.name?.first?.trim() ?? '';
        final last = contact.name?.last?.trim() ?? '';
        name = '$first $last'.trim();
      }
      if (name.isEmpty) name = 'Cliente';

      if (_step == ChatFlowStep.findBudgetAskName) {
        await _sendUserMessageWithId(_generateMessageId(), name);
        await _findBudget(name);
        return Result.ok(null);
      }

      String? phone;
      final phones = contact.phones;
      if (phones.isNotEmpty) {
        final rawPhone = phones.first.number
            .replaceAll('+55', '')
            .replaceAll('+', '')
            .replaceAll(RegExp(r'\D'), '');
        if (rawPhone.isNotEmpty) {
          if (rawPhone.length < 10 || rawPhone.length > 11) {
            phone = null;
          } else {
            phone = _phoneMask.maskText(rawPhone);
          }
        }
      }

      final nameMsgId = _generateMessageId();
      await _sendUserMessageWithId(
        nameMsgId,
        name,
        payload: {'editableField': 'clientName'},
      );
      _clientNameMsgId = nameMsgId;
      _pendingClientName = name;

      if (phone == null || phone.isEmpty) {
        _setStep(ChatFlowStep.askPhone);
        await _addBotMessage(
          _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
          type: ChatMessageType.text,
        );
        return Result.ok(null);
      }

      _pendingPhone = phone;
      return await _showClientDataConfirmation();
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  Future<Result<void>> _createDraftFromName() async {
    final name = textController.text.trim();
    if (name.isEmpty) return Result.ok(null);
    textController.clear();

    final msgId = _generateMessageId();
    await _sendUserMessageWithId(
      msgId,
      name,
      payload: {'editableField': 'clientName'},
    );
    _clientNameMsgId = msgId;

    _pendingClientName = name;
    _setStep(ChatFlowStep.askPhone);
    await _addBotMessage(
      _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
      type: ChatMessageType.text,
    );
    return Result.ok(null);
  }

  Future<Result<void>> _showClientDataConfirmation() async {
    _setStep(ChatFlowStep.confirmClientData);
    await _addBotMessage(
      ChatAssistantStrings.confirmClientData(_pendingClientName, _pendingPhone),
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['Confirmar dados', 'Editar nome', 'Editar telefone'],
      },
    );
    return Result.ok(null);
  }

  void prepareEditMessage(String field, String currentText, String messageId) {
    textController.text = currentText;
    _editingMsgId = messageId;
    _editingField = field;
    notifyListeners();
  }

  Future<Result<void>> _askEditName() async {
    if (_clientNameMsgId == null) return Result.ok(null);
    _prepareEditField('clientName', _pendingClientName, _clientNameMsgId!);
    return Result.ok(null);
  }

  Future<Result<void>> _askEditPhone() async {
    if (_clientPhoneMsgId == null) return Result.ok(null);
    _prepareEditField('clientPhone', _pendingPhone, _clientPhoneMsgId!);
    return Result.ok(null);
  }

  void _prepareEditField(String field, String currentText, String msgId) {
    textController.text = currentText;
    _editingMsgId = msgId;
    _editingField = field;
    notifyListeners();
  }

  void cancelEdit() {
    _editingMsgId = null;
    _editingField = null;
    textController.clear();
    notifyListeners();
  }

  Future<Result<void>> _createDraftAndGoToAddress(
    String clientName, {
    String? phone,
  }) async {
    final result = await _usecase.createDraft(clientName, phone: phone);

    if (result is Ok<CustomerInfo>) {
      _setStep(ChatFlowStep.askAddress);
      await _addBotMessage(
        _script?.askAddress ?? ChatScriptEntity.fallback.askAddress,
        type: ChatMessageType.inlineButtons,
        payload: {
          'actions': ['SIM', 'NÃO'],
        },
      );
    } else if (result is Error<CustomerInfo>) {
      await _addBotMessage(
        ChatAssistantStrings.createBudgetFailed,
        type: ChatMessageType.text,
      );
    }
    return Result.ok(null);
  }

  Future<Result<void>> _skipAddress() async {
    _setStep(ChatFlowStep.askProducts);
    await _addBotMessage(
      _script?.askProducts ?? ChatScriptEntity.fallback.askProducts,
      type: ChatMessageType.action,
      payload: {
        'label': ChatAssistantStrings.selectProductsLabel,
        'action': 'open_products',
      },
    );
    return Result.ok(null);
  }

  Future<Result<void>> _askForCep() async {
    _setStep(ChatFlowStep.askCep);
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: _script?.askCep ?? ChatScriptEntity.fallback.askCep,
        labels: const [],
        step: ChatFlowStep.askCep.name,
        backLabel: ChatAssistantStrings.menuBackLabel,
      ),
    );
    return Result.ok(null);
  }

  Future<Result<void>> _goToManualAddress() async {
    _isCorrectingAddress = false;
    _pendingAddress = null;
    streetController.clear();
    numberController.clear();
    cityController.clear();
    neighborhoodController.clear();
    _setStep(ChatFlowStep.askStreetManual);
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content:
            _script?.askStreetFallback ??
            ChatScriptEntity.fallback.askStreetFallback,
        labels: const [],
        step: ChatFlowStep.askStreetManual.name,
        backLabel: ChatAssistantStrings.menuBackLabel,
      ),
    );
    return Result.ok(null);
  }

  String _upper(String? v) => (v ?? '').trim().toUpperCase();

  Future<Result<void>> _submitCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) {
      await _addBotMessage(
        ChatAssistantStrings.invalidCep,
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    final viaCep = getIt<CepRepository>();
    final address = await viaCep.getAddress(cep);

    if (address.logradouro == null || address.logradouro!.isEmpty) {
      _isCorrectingAddress = false;
      _pendingAddress = null;
      _setStep(ChatFlowStep.askStreetManual);
      await _addBotMessage(
        _script?.cepNotFound ?? ChatScriptEntity.fallback.cepNotFound,
        type: ChatMessageType.text,
      );
      await _addBotMessage(
        _script?.askStreetFallback ??
            ChatScriptEntity.fallback.askStreetFallback,
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    _pendingAddress = address;
    _pendingAddress!.cep = _cepMask.maskText(cep);

    _setStep(ChatFlowStep.confirmCepAddress);
    await _addBotMessage(
      ChatAssistantStrings.foundAddress(
        _upper(address.logradouro),
        address.bairro != null && address.bairro!.isNotEmpty
            ? _upper(address.bairro)
            : null,
        _upper(address.localidade),
      ),
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['Confirmar endereço', 'Corrigir endereço'],
        'backLabel': ChatAssistantStrings.menuBackLabel,
      },
    );
    return Result.ok(null);
  }

  // ------------------------------------------------------------------
  // Salvar endereço no OwnerPdf (fluxo de edição de PDF)
  // ------------------------------------------------------------------
  Future<void> _savePdfAddress({
    String? street,
    String? city,
    String? neighborhood,
    String? zip,
  }) async {
    final fetchResult = await _pdfRepo.fetchInformationEnterprise();
    if (fetchResult is Error<OwnerPdf>) {
      await _addBotMessage(
        ChatAssistantStrings.fetchPdfDataError(fetchResult.error),
        type: ChatMessageType.text,
      );
      return;
    }
    final current = (fetchResult as Ok<OwnerPdf>).value;
    final updated = OwnerPdf(
      rua: street ?? current.rua,
      empresa: current.empresa,
      email: current.email,
      cnpj: current.cnpj,
      bairro: neighborhood ?? current.bairro,
      city: city ?? current.city,
      cep: zip ?? current.cep,
      fotoId: current.fotoId,
      fone: current.fone,
      logoName: current.logoName,
      pdfLayoutType: current.pdfLayoutType,
    );
    final saveResult = await _pdfRepo.saveInformationEnterprise(updated);
    if (saveResult is Error<void>) {
      await _addBotMessage(
        ChatAssistantStrings.saveAddressError(saveResult.error),
        type: ChatMessageType.text,
      );
    }
  }

  Future<void> _finishPdfAddressFlow() async {
    _pendingAddress = null;
    _isCorrectingAddress = false;
    _isPdfEditAddressMode = false;

    await _addBotMessage(
      ChatAssistantStrings.pdfEditSuccessAddress,
      type: ChatMessageType.text,
    );
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.pdfEditNextQuestion,
        labels: ChatAssistantStrings.pdfEditNextOptionLabels,
        step: ChatFlowStep.pdfEditConfirm.name,
      ),
    );
    _setStep(ChatFlowStep.pdfEditConfirm);
  }

  Future<Result<void>> _confirmCepAddress() async {
    if (_pendingAddress == null) return Result.ok(null);

    if (_isPdfEditAddressMode) {
      await _savePdfAddress(
        zip: _pendingAddress!.cep,
        street: _upper(_pendingAddress!.logradouro),
        city: _upper(_pendingAddress!.localidade),
        neighborhood: _upper(_pendingAddress!.bairro),
      );
      await _finishPdfAddressFlow();
      return Result.ok(null);
    }

    await _usecase.updateAddress(
      zip: _pendingAddress!.cep,
      street: _upper(_pendingAddress!.logradouro),
      city: _upper(_pendingAddress!.localidade),
      neighborhood: _upper(_pendingAddress!.bairro),
    );

    _pendingAddress = null;
    _isCorrectingAddress = false;

    _setStep(ChatFlowStep.askProducts);
    await _addBotMessage(
      ChatAssistantStrings.addressSaved,
      type: ChatMessageType.text,
    );
    await _addBotMessage(
      _script?.askProducts ?? ChatScriptEntity.fallback.askProducts,
      type: ChatMessageType.action,
      payload: {
        'label': ChatAssistantStrings.selectProductsLabel,
        'action': 'open_products',
      },
    );
    return Result.ok(null);
  }

  Future<Result<void>> _submitManualAddress() async {
    final street = _upper(streetController.text.trim());
    final number = numberController.text.trim();
    final city = _upper(cityController.text.trim());
    final neighborhood = _upper(neighborhoodController.text.trim());

    if (street.isEmpty || city.isEmpty) {
      await _addBotMessage(
        ChatAssistantStrings.streetAndCityRequired,
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    final fullStreet = number.isNotEmpty ? '$street, $number' : street;

    if (_isPdfEditAddressMode) {
      await _savePdfAddress(
        zip:
            _isCorrectingAddress
                ? _cepMask.maskText(cepController.text.trim())
                : null,
        street: fullStreet,
        city: city,
        neighborhood: neighborhood.isEmpty ? null : neighborhood,
      );
      streetController.clear();
      numberController.clear();
      cityController.clear();
      neighborhoodController.clear();
      await _finishPdfAddressFlow();
      return Result.ok(null);
    }

    await _usecase.updateAddress(
      zip:
          _isCorrectingAddress
              ? _cepMask.maskText(cepController.text.trim())
              : null,
      street: fullStreet,
      city: city,
      neighborhood: neighborhood.isEmpty ? null : neighborhood,
    );

    streetController.clear();
    numberController.clear();
    cityController.clear();
    neighborhoodController.clear();
    _isCorrectingAddress = false;
    _pendingAddress = null;

    _setStep(ChatFlowStep.askProducts);
    await _addBotMessage(
      ChatAssistantStrings.addressSaved,
      type: ChatMessageType.text,
    );
    await _addBotMessage(
      _script?.askProducts ?? ChatScriptEntity.fallback.askProducts,
      type: ChatMessageType.action,
      payload: {
        'label': ChatAssistantStrings.selectProductsLabel,
        'action': 'open_products',
      },
    );
    return Result.ok(null);
  }

  Future<Result<void>> _cancelCorrectionAndConfirm() async {
    if (_pendingAddress == null) return Result.ok(null);

    if (_isPdfEditAddressMode) {
      await _savePdfAddress(
        zip: _pendingAddress!.cep,
        street: _upper(_pendingAddress!.logradouro),
        city: _upper(_pendingAddress!.localidade),
        neighborhood: _upper(_pendingAddress!.bairro),
      );
      streetController.clear();
      numberController.clear();
      cityController.clear();
      neighborhoodController.clear();
      await _finishPdfAddressFlow();
      return Result.ok(null);
    }

    await _usecase.updateAddress(
      zip: _pendingAddress!.cep,
      street: _upper(_pendingAddress!.logradouro),
      city: _upper(_pendingAddress!.localidade),
      neighborhood: _upper(_pendingAddress!.bairro),
    );

    streetController.clear();
    numberController.clear();
    cityController.clear();
    neighborhoodController.clear();
    _isCorrectingAddress = false;
    _pendingAddress = null;

    _setStep(ChatFlowStep.askProducts);
    await _addBotMessage(
      ChatAssistantStrings.addressSaved,
      type: ChatMessageType.text,
    );
    await _addBotMessage(
      _script?.askProducts ?? ChatScriptEntity.fallback.askProducts,
      type: ChatMessageType.action,
      payload: {
        'label': ChatAssistantStrings.selectProductsLabel,
        'action': 'open_products',
      },
    );
    return Result.ok(null);
  }

  Future<Result<void>> _confirmProducts(
    List<ItemsBudget> items, {
    bool isEdit = false,
  }) async {
    if (isEdit && _currentDraftItems.isNotEmpty) {
      await _chatRepo.removeItemsFromDraft(_currentDraftItems);
      _currentDraftItems.clear();
    }

    await _usecase.addProducts(items);
    _currentDraftItems.addAll(items);

    return await _showProductReviewAndComments();
  }

  Future<Result<void>> _editProducts(List<ItemsBudget> items) async {
    return _confirmProducts(items, isEdit: true);
  }

  Future<Result<void>> _showProductReviewAndComments() async {
    if (_reviewMsgId != null) {
      await _chatRepo.removeMessageById(_reviewMsgId!);
      _reviewMsgId = null;
    }
    if (_commentQuestionMsgId != null) {
      await _chatRepo.removeMessageById(_commentQuestionMsgId!);
      _commentQuestionMsgId = null;
    }

    final result = await _chatRepo.fetchDraftItems();
    final List<ItemsBudget> items;
    if (result is Ok<List<ItemsBudget>>) {
      items = result.value;
    } else {
      items = List<ItemsBudget>.from(_currentDraftItems);
    }

    final buffer = StringBuffer();
    double grandTotal = 0;
    if (items.isEmpty) {
      buffer.writeln(ChatAssistantStrings.noBudgetItems);
    } else {
      buffer.writeln(ChatAssistantStrings.budgetItemsTitle);
      for (final it in items) {
        final lineTotal = it.total ?? ((it.quantity ?? 0) * (it.price ?? 0));
        grandTotal += lineTotal;
        buffer.writeln(
          '• ${it.description} — ${(it.quantity ?? 1).toInt()}x '
          'R\$ ${(it.price ?? 0).toStringAsFixed(2)} = '
          'R\$ ${lineTotal.toStringAsFixed(2)}',
        );
      }
      buffer.writeln('');
      buffer.writeln(
        ChatAssistantStrings.budgetItemsTotal(grandTotal.toStringAsFixed(2)),
      );
    }

    _setStep(ChatFlowStep.askComments);

    _reviewMsgId = _generateMessageId();
    await _sendBotMessageWithId(
      _reviewMsgId!,
      buffer.toString(),
      type: ChatMessageType.productList,
    );

    _commentQuestionMsgId = _generateMessageId();
    await _sendBotMessageWithId(
      _commentQuestionMsgId!,
      ChatAssistantStrings.askAddComments,
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['SIM', 'NÃO'],
      },
    );

    return Result.ok(null);
  }

  Future<Result<void>> _finalizeAndShare() async {
    final result = await _usecase.finalize();

    if (result is Ok<CustomerInfo>) {
      _setStep(ChatFlowStep.shareLink);
      await _addBotMessage(
        ChatAssistantStrings.budgetCreatedSuccess,
        type: ChatMessageType.inlineButtons,
        payload: {
          'actions': _buildFinalActions(),
          'backLabel': ChatAssistantStrings.menuBackLabel,
        },
      );
    } else {
      await _addBotMessage(
        ChatAssistantStrings.finalizeBudgetFailed,
        type: ChatMessageType.text,
      );
    }
    return Result.ok(null);
  }

  Future<Result<void>> _shareLink() async {
    final budgetId = _chatRepo.draftBudget?.id;
    if (budgetId == null || budgetId.isEmpty) {
      _shareErrorMessage = ChatAssistantStrings.budgetNotAvailableToShare;
      return Result.error(Exception(_shareErrorMessage));
    }

    final url = await getIt<ShareLinkRepository>().buildShareUrl(
      enderecoNumero: budgetId,
    );
    if (url == null || url.isEmpty) {
      _shareErrorMessage = ChatAssistantStrings.shareLinkFailed;
      return Result.error(Exception(_shareErrorMessage));
    }

    _shareErrorMessage = null;
    await SharePlus.instance.share(
      ShareParams(text: url, subject: ChatAssistantStrings.shareSubject),
    );
    // A cada compartilhamento, não assinantes veem um intersticial.
    // `showInterstitial` já suprime para assinantes e recarrega o próximo.
    getIt<AdsRepository>().showInterstitial();
    return Result.ok(null);
  }

  Future<Result<void>> _copyLink() async {
    final budgetId = _chatRepo.draftBudget?.id;
    if (budgetId == null || budgetId.isEmpty) {
      _shareErrorMessage = ChatAssistantStrings.budgetNotAvailableToShare;
      return Result.error(Exception(_shareErrorMessage));
    }
    final url = await getIt<ShareLinkRepository>().buildShareUrl(
      enderecoNumero: budgetId,
    );
    if (url == null || url.isEmpty) {
      _shareErrorMessage = ChatAssistantStrings.shareLinkFailed;
      return Result.error(Exception(_shareErrorMessage));
    }
    _shareErrorMessage = null;
    await Clipboard.setData(ClipboardData(text: url));
    return Result.ok(null);
  }

  Future<Result<void>> _generateBudgetPdf() async {
    final result = await _generatePdf();
    if (result is Error<void>) {
      _shareErrorMessage = ChatAssistantStrings.pdfUnavailable;
      return result;
    }
    _shareErrorMessage = null;
    _pendingNavigation = openBudgetPdfAction;
    notifyListeners();
    return Result.ok(null);
  }

  Future<Result<void>> _resetChat() async {
    if (_step != ChatFlowStep.shareLink) {
      await _chatRepo.deleteDraft();
    }
    _clearLocalState();
    final step = await _resetToMenuUsecase(withReports: _aiMode);
    _setStepFromName(step);
    return Result.ok(null);
  }

  // ------------------------------------------------------------------
  // Helpers de mensagens
  // ------------------------------------------------------------------
  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _addBotMessage(
    String text, {
    ChatMessageType type = ChatMessageType.text,
    Map<String, dynamic>? payload,
  }) async {
    final msg = ChatMessageEntity(
      id: _generateMessageId(),
      sender: ChatSender.bot,
      type: type,
      content: text,
      payload: payload,
      timestamp: DateTime.now(),
    );
    await _chatRepo.sendMessage(msg);
  }

  Future<void> _sendBotMessageWithId(
    String id,
    String text, {
    ChatMessageType type = ChatMessageType.text,
    Map<String, dynamic>? payload,
  }) async {
    final msg = ChatMessageEntity(
      id: id,
      sender: ChatSender.bot,
      type: type,
      content: text,
      payload: payload,
      timestamp: DateTime.now(),
    );
    await _chatRepo.sendMessage(msg);
  }

  Future<void> _sendUserMessageWithId(
    String id,
    String text, {
    Map<String, dynamic>? payload,
  }) async {
    final msg = ChatMessageEntity(
      id: id,
      sender: ChatSender.user,
      type: ChatMessageType.text,
      content: text,
      payload: payload,
      timestamp: DateTime.now(),
    );
    await _chatRepo.sendMessage(msg);
  }

  Future<Result<void>> _noop() async => Result.ok(null);

  void _onRepoChanged() {
    if (!_disposed) notifyListeners();
  }

  void _onCommandDone() {
    if (!_disposed &&
        (shareLinkCommand.error ||
            shareLinkCommand.completed ||
            copyLinkCommand.error ||
            copyLinkCommand.completed ||
            generatePdfCommand.error ||
            generatePdfCommand.completed)) {
      notifyListeners();
    }
  }

  void clearShareError() {
    _shareErrorMessage = null;
    shareLinkCommand.clearResult();
    copyLinkCommand.clearResult();
    generatePdfCommand.clearResult();
  }

  // ------------------------------------------------------------------
  // Ação de botões inline
  // ------------------------------------------------------------------
  Future<void> handleAction(String action) async {
    if (_pendingAgentAction != null &&
        (action == ChatAssistantStrings.aiConfirmLabel ||
            action == ChatAssistantStrings.aiCancelLabel)) {
      await _resolveAgentAction(
        confirmed: action == ChatAssistantStrings.aiConfirmLabel,
      );
      return;
    }
    if (action.startsWith('share_url|')) {
      await SharePlus.instance.share(
        ShareParams(text: action.substring('share_url|'.length)),
      );
      return;
    }
    switch (action) {
      case 'pick_contact':
        await pickContactCommand.execute();
        break;
      case 'back_to_menu':
        // No modo IA o step fica em mainMenu: o voltar ainda precisa funcionar.
        if (_step == ChatFlowStep.mainMenu && !_aiMode) break;
        await _sendUserMessageWithId(
          _generateMessageId(),
          ChatAssistantStrings.menuBackLabel,
        );
        await _backToMainMenu();
        break;
      case 'SIM':
        if (_step == ChatFlowStep.askAddress) {
          _setStep(ChatFlowStep.askHasCep);
          await _addBotMessage(
            _script?.askHasCep ?? ChatScriptEntity.fallback.askHasCep,
            type: ChatMessageType.inlineButtons,
            payload: {
              'actions': ['SIM', 'NÃO'],
            },
          );
        } else if (_step == ChatFlowStep.askHasCep) {
          await _askForCep();
        }
        break;
      case 'NÃO':
        if (_step == ChatFlowStep.askAddress) {
          await skipAddressCommand.execute();
        } else if (_step == ChatFlowStep.askHasCep) {
          await _goToManualAddress();
        } else if (_step == ChatFlowStep.askComments) {
          await _finalizeAndShare();
        }
        break;
      case 'has_cep_yes':
        await _askForCep();
        break;
      case 'has_cep_no':
        await _goToManualAddress();
        break;
      case 'Confirmar endereço':
        await confirmCepAddressCommand.execute();
        break;
      case 'Corrigir endereço':
        _isCorrectingAddress = true;
        cepController.text = _cepMask.maskText(_pendingAddress?.cep ?? '');
        streetController.text = _upper(_pendingAddress?.logradouro);
        cityController.text = _upper(_pendingAddress?.localidade);
        neighborhoodController.text = _upper(_pendingAddress?.bairro);
        numberController.clear();
        _setStep(ChatFlowStep.askStreetManual);
        await _addBotMessage(
          _script?.askStreetFallback ??
              ChatScriptEntity.fallback.askStreetFallback,
          type: ChatMessageType.text,
        );
        break;
      case 'Confirmar dados':
        await _createDraftAndGoToAddress(
          _pendingClientName,
          phone: _pendingPhone,
        );
        break;
      case 'Editar nome':
        await _askEditName();
        break;
      case 'Editar telefone':
        await _askEditPhone();
        break;
      case 'open_products':
        break;
      case 'share_link':
        await shareLinkCommand.execute();
        break;
      case 'finalize_budget':
        await _finalizeAndShare();
        break;
      case 'edit_products':
        break;
      case 'cancel_and_proceed':
        await _cancelCorrectionAndConfirm();
        break;
    }
  }

  // ------------------------------------------------------------------
  // Callback da View após criar produto
  // ------------------------------------------------------------------
  Future<void> onProductCreatedFromChat() async {
    final productRepo = getIt<ProductPriceRepository>();
    final result = await productRepo.fetchProducts();

    ProductPriceModel? lastProduct;
    if (result is Ok<List<ProductPriceModel>> && result.value.isNotEmpty) {
      lastProduct = result.value.last;
    }

    if (lastProduct != null) {
      final desc = lastProduct.descricao ?? 'Produto';
      final preco = (lastProduct.preco ?? 0).toStringAsFixed(2);
      final categoria = lastProduct.categoria ?? 'Serviços';

      await _addBotMessage(
        ChatAssistantStrings.productCreatedDetails(desc, preco, categoria),
        type: ChatMessageType.inlineButtons,
        payload: {
          'actions': ['Abrir lista de produtos'],
        },
      );
    } else {
      await _addBotMessage(
        ChatAssistantStrings.productCreated,
        type: ChatMessageType.text,
      );
    }

    final step = await _showPriceListUsecase();
    _setStepFromName(step);
    notifyListeners();
  }

  Future<void> goToCommentsAfterProductEdit() async {
    await _chatRepo.refreshDraftTotal();
    await _showProductReviewAndComments();
  }

  Future<void> finalizeAfterComments() async {
    _setStep(ChatFlowStep.askComments);

    if (_commentsFeedbackMsgId != null &&
        _chatRepo.messages.any((m) => m.id == _commentsFeedbackMsgId)) {
      return;
    }

    final msgId = _generateMessageId();
    _commentsFeedbackMsgId = msgId;

    await _sendBotMessageWithId(
      msgId,
      ChatAssistantStrings.commentsUpdated,
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['Editar comentários', 'Finalizar e gerar link'],
      },
    );
  }

  // ------------------------------------------------------------------
  // Callbacks dos fluxos externos
  // ------------------------------------------------------------------
  Future<void> onLogoUpdated() async {
    final step = await _onLogoUpdated();
    _setStepFromName(step);
    notifyListeners();
  }

  Future<void> onPdfModelSelected() async {
    await _addBotMessage(
      ChatAssistantStrings.pdfModelSelected,
      type: ChatMessageType.text,
    );
    final step = await _showPdfEditUsecase();
    _setStepFromName(step);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Decisões que antes ficavam na View (§16.3 do CHAT_AI_AGENT_PLAN).
  // A View só abre telas/modais; o que abrir é decidido aqui.
  // ------------------------------------------------------------------

  /// Navegações que a View executa (precisam de `context`).
  static const openProductsNav = 'open_products';
  static const openCommentsNav = 'open_comments';
  static const openExistingCommentsNav = 'open_existing_comments';
  static const openLogoEditNav = 'open_logo_edit';
  static const linkCopiedNav = 'link_copied';

  /// Toque num botão de mensagem. Retorna a navegação que a View deve
  /// executar, ou `null` quando a ViewModel já tratou tudo.
  Future<String?> onButtonAction(ChatMessageEntity msg, String action) async {
    markButtonUsed(msg, action);
    if (action.startsWith(findBudgetAction) ||
        action == DispatchAgentToolUsecase.selectReceiptBudget ||
        action == selectProofBudgetAction ||
        action.startsWith(openProofsAction) ||
        action == DispatchAgentToolUsecase.selectDuplicateBudget ||
        action == DispatchAgentToolUsecase.selectCommentBudget ||
        action.startsWith('open_budget|')) {
      return action;
    }
    if (action == ChatAssistantStrings.copyLinkLabel) {
      await copyLinkCommand.execute();
      return copyLinkCommand.completed ? linkCopiedNav : null;
    }
    if (action == ChatAssistantStrings.generatePdfLabel) {
      await generatePdfCommand.execute();
      return null;
    }
    switch (action) {
      case 'pick_contact':
        await pickContactCommand.execute();
      case 'SIM':
        if (_step == ChatFlowStep.askComments) return openCommentsNav;
        if (_step == ChatFlowStep.askExistingBudgetComments) {
          return openExistingCommentsNav;
        }
        await handleAction('SIM');
      case 'Sim':
        if (_step == ChatFlowStep.pdfEditConfirmEntry) {
          await sendTextCommand.execute('Sim');
        } else {
          await handleAction(action);
        }
      case 'NÃO':
        if (_step == ChatFlowStep.askExistingBudgetComments) {
          await skipExistingBudgetComments();
        } else if (_step == ChatFlowStep.askComments) {
          await handleAction('NÃO');
        } else {
          await skipAddressCommand.execute();
        }
      case 'Não':
        if (_step == ChatFlowStep.pdfEditConfirmEntry) {
          await sendTextCommand.execute('Não');
        } else if (_step == ChatFlowStep.askComments) {
          await handleAction('NÃO');
        } else {
          await skipAddressCommand.execute();
        }
      case 'open_products':
      case 'edit_products':
        return openProductsNav;
      case 'share_link':
        await shareLinkCommand.execute();
      case 'edit_comments':
      case 'Editar comentários':
        return openCommentsNav;
      case 'finalize_budget':
      case 'Finalizar e gerar link':
        await handleAction('finalize_budget');
      case 'cancel_and_proceed':
        await handleAction('cancel_and_proceed');
      case 'open_logo_edit':
        return openLogoEditNav;
      default:
        // Ações sem interação de UI (Confirmar endereço, Corrigir endereço…)
        await handleAction(action);
    }
    return null;
  }

  /// Toque numa opção de [ChatMessageType.optionList].
  void selectOption(ChatMessageEntity msg, String value, String label) {
    markButtonUsed(msg, value);
    selectOptionCommand.execute((
      value: value,
      label: label,
      step: msg.payload?['optionsStep'] as String? ?? '',
    ));
  }

  /// Envia o texto digitado (botão enviar).
  void submitInput() {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    textController.clear();
    sendTextCommand.execute(text);
  }

  /// Campo de digitação habilitado no step atual.
  bool get inputEnabled =>
      !isLoading &&
      _step != ChatFlowStep.askAddress &&
      _step != ChatFlowStep.reviewProducts &&
      _step != ChatFlowStep.shareLink &&
      !isSavingProof;

  /// Mostra o formulário de endereço manual no lugar da barra de texto.
  bool get showManualAddressForm => _step == ChatFlowStep.askStreetManual;

  /// Erro de compartilhar/copiar/gerar PDF a exibir (`null` = nenhum).
  String? get shareErrorToShow =>
      (shareLinkCommand.error ||
              copyLinkCommand.error ||
              generatePdfCommand.error)
          ? (_shareErrorMessage ?? ChatAssistantStrings.shareError)
          : null;

  /// Aviso/erro de anexos de comprovante: arquivos cortados = aviso;
  /// recusa = erro. `message == null` → nada a mostrar.
  ({bool isWarning, String? message}) proofIssueAlert(
    ProofAttachmentValidation v,
  ) => (
    isWarning: v.issue == null || v.issue == ProofAttachmentIssue.mixed,
    message: switch (v.issue) {
      ProofAttachmentIssue.tooBig => PaymentProofStrings.tooBig,
      ProofAttachmentIssue.invalidType => PaymentProofStrings.invalidType,
      ProofAttachmentIssue.mixed => PaymentProofStrings.mixedTypes,
      ProofAttachmentIssue.empty => null,
      null => v.trimmed ? PaymentProofStrings.onlyFirstFiles : null,
    },
  );

  /// Anexos aptos a abrir a prévia (aviso de "mixed" ainda segue).
  bool canPreviewProof(ProofAttachmentValidation v) =>
      v.files.isNotEmpty &&
      (v.issue == null || v.issue == ProofAttachmentIssue.mixed);

  /// Dados para editar a logo. `null` = não assinante (abrir assinatura).
  Future<OwnerPdf?> ownerForLogoEdit() async {
    final isSubscribed =
        getIt<UserRepository>().selectUser.value?.autoRenewing ?? false;
    if (!isSubscribed) return null;
    final result = await _pdfRepo.fetchInformationEnterprise();
    return result is Ok<OwnerPdf> ? result.value : OwnerPdf();
  }

  /// Voltou da tela do PDF do orçamento recém-criado.
  void onBudgetPdfClosed() => getIt<BudgetRepository>().clearSelectBudget();

  /// Voltou da seleção de modelo de PDF.
  Future<void> onPdfModelSelectClosed(bool selected) async {
    if (selected) {
      await onPdfModelSelected();
    } else {
      await repeatCurrentMenu();
    }
  }

  /// Voltou do modal de criar produto.
  Future<void> onProductCreatorClosed(bool saved) async {
    if (saved) {
      await onProductCreatedFromChat();
    } else {
      await repeatCurrentMenu();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _chatRepo.removeListener(_onRepoChanged);
    _scriptRepo.removeListener(_onRepoChanged);
    shareLinkCommand.removeListener(_onCommandDone);
    copyLinkCommand.removeListener(_onCommandDone);
    generatePdfCommand.removeListener(_onCommandDone);
    textController.dispose();
    cepController.dispose();
    streetController.dispose();
    numberController.dispose();
    cityController.dispose();
    neighborhoodController.dispose();
    super.dispose();
  }
}

/// Toque em um botão de [ChatMessageType.optionList].
typedef ChatOptionTap = ({String value, String label, String step});
