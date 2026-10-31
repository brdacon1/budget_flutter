import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as user_info;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_script_repository.dart';
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
import 'package:oflite/modules/chat_assistant/presenter/enum/chat_flow_step_enum.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_pdf_edit_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_price_list_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/core/cep/data/model/address.dart';
import 'package:oflite/modules/core/cep/domain/repository/cep_repository.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:share_plus/share_plus.dart';

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
  ) {
    _chatRepo.addListener(_onRepoChanged);
    _scriptRepo.addListener(_onRepoChanged);
    shareLinkCommand.addListener(_onCommandDone);
  }

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

  String? _pdfEditField;

  String? _pendingNavigation;
  String? get pendingNavigation => _pendingNavigation;

  void clearPendingNavigation() {
    _pendingNavigation = null;
  }

  late final Command0<void> initializeChat = Command0(_initialize);
  late final Command1<void, String> sendTextCommand = Command1(_sendText);
  late final Command0<void> pickContactCommand = Command0(_pickContact);
  late final Command0<void> createDraftCommand = Command0(_createDraftFromName);
  late final Command0<void> skipAddressCommand = Command0(_skipAddress);
  late final Command1<void, String> submitCepCommand = Command1(_submitCep);
  late final Command0<void> confirmCepAddressCommand = Command0(_confirmCepAddress);
  late final Command0<void> submitManualAddressCommand = Command0(_submitManualAddress);
  late final Command0<void> openProductSelectionCommand = Command0(_noop);
  late final Command1<void, List<ItemsBudget>> confirmProductsCommand = Command1(_confirmProducts);
  late final Command1<void, List<ItemsBudget>> editProductsCommand = Command1(_editProducts);
  late final Command0<void> shareLinkCommand = Command0(_shareLink);
  late final Command0<void> resetChatCommand = Command0(_resetChat);

  // ------------------------------------------------------------------
  // Inicialização
  // ------------------------------------------------------------------
  Future<Result<void>> _initialize() async {
    _clearLocalState();
    try {
      await _fetchScriptUsecase.call();
    } catch (_) {}
    final step = await _resetToMenuUsecase();
    _setStepFromName(step);
    notifyListeners();
    return Result.ok(null);
  }

  Future<void> _backToMainMenu() async {
    _clearLocalState();
    final step = await _resetToMenuUsecase();
    _setStepFromName(step);
    notifyListeners();
  }

  void _clearLocalState() {
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
    _pdfEditField = null;
    _pendingNavigation = null;
    _isPdfEditAddressMode = false;
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
  // Envia texto do usuário
  // ------------------------------------------------------------------
  Future<Result<void>> _sendText(String text) async {
    if (text.trim().isEmpty) return Result.ok(null);
    final clean = text.trim();

    // Em qualquer fluxo, "0" volta ao menu principal
    if (clean == '0' && _step != ChatFlowStep.mainMenu) {
      await _backToMainMenu();
      return Result.ok(null);
    }

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
    await _sendUserMessageWithId(msgId, clean, payload: userPayload);

    if (_step == ChatFlowStep.askClient) {
      _clientNameMsgId = msgId;
    } else if (_step == ChatFlowStep.askPhone) {
      _clientPhoneMsgId = msgId;
    }

    try {
      if (_step == ChatFlowStep.mainMenu) {
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
      } else if (_step == ChatFlowStep.welcome || _step == ChatFlowStep.askClient) {
        _pendingClientName = clean;
        _setStep(ChatFlowStep.askPhone);
        await _addBotMessage(
          _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
          type: ChatMessageType.text,
        );
      } else if (_step == ChatFlowStep.askPhone) {
        if (!_isValidPhone(clean)) {
          await _addBotMessage(
            'Telefone inválido. Informe apenas números com DDD. Ex: (11) 99999-9999 ou 11999999999.',
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
            'Opção inválida. Digite 1 para Sim ou 2 para Não.',
            type: ChatMessageType.text,
          );
        }
      } else if (_step == ChatFlowStep.askCep) {
        await _submitCep(clean);
      }
    } catch (e) {
      await _addBotMessage(
        'Erro ao processar: $e',
        type: ChatMessageType.text,
      );
    }
    return Result.ok(null);
  }

  // ------------------------------------------------------------------
  // Handlers de menus delegando para UseCases
  // ------------------------------------------------------------------
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
        ChatBudgetStrings.menuInvalidOption,
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
        '${ChatBudgetStrings.changeUsernameSuccess} $newName',
        type: ChatMessageType.text,
      );
    } else {
      // Usuário cancelou ou não alterou
      await _addBotMessage(
        ChatBudgetStrings.changeUsernameNotChanged,
        type: ChatMessageType.text,
      );
    }

    await _addBotMessage(
      '${ChatBudgetStrings.changeUsernameRetryQuestion}\n'
      '${ChatBudgetStrings.menuBackOption}',
      type: ChatMessageType.text,
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
          ChatBudgetStrings.menuInvalidOption,
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
      final hasPermission = await user_info.FlutterContacts.requestPermission();
      if (!hasPermission) return Result.ok(null);

      final contact = await user_info.FlutterContacts.openExternalPick();
      if (contact == null) return Result.ok(null);

      String name = contact.displayName.trim();
      if (name.isEmpty) {
        final first = contact.name.first.trim();
        final last = contact.name.last.trim();
        name = '$first $last'.trim();
      }
      if (name.isEmpty) name = 'Cliente';

      String? phone;
      final phones = contact.phones;
      if (phones.isNotEmpty) {
        phone = phones.first.number
            .replaceAll('+55', '')
            .replaceAll('+', '')
            .replaceAll(RegExp(r'\D'), '');
        if (phone.isNotEmpty) {
          if (phone.length < 10 || phone.length > 11) {
            phone = null;
          } else {
            phone = _phoneMask.maskText(phone);
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
      'Confirme os dados do cliente:\n'
      'Nome: $_pendingClientName\n'
      'Telefone: ${_pendingPhone.isEmpty ? '—' : _pendingPhone}',
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['Confirmar dados', 'Editar nome', 'Editar telefone']
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
        payload: {'actions': ['SIM', 'NÃO']},
      );
    } else if (result is Error<CustomerInfo>) {
      await _addBotMessage(
        'Ops, não consegui criar o orçamento. Tente novamente.',
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
        'label': 'Selecionar produtos',
        'action': 'open_products',
      },
    );
    return Result.ok(null);
  }

  Future<Result<void>> _askForCep() async {
    _setStep(ChatFlowStep.askCep);
    await _addBotMessage(
      '${_script?.askCep ?? ChatScriptEntity.fallback.askCep}\n\n'
      '${ChatBudgetStrings.menuBackOption}',
      type: ChatMessageType.text,
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
    await _addBotMessage(
      '${_script?.askStreetFallback ?? ChatScriptEntity.fallback.askStreetFallback}\n\n'
      '${ChatBudgetStrings.menuBackOption}',
      type: ChatMessageType.text,
    );
    return Result.ok(null);
  }

  String _upper(String? v) => (v ?? '').trim().toUpperCase();

  Future<Result<void>> _submitCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) {
      await _addBotMessage(
        'CEP inválido. Digite 8 números.',
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
        _script?.askStreetFallback ?? ChatScriptEntity.fallback.askStreetFallback,
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    _pendingAddress = address;
    _pendingAddress!.cep = cep;

    _setStep(ChatFlowStep.confirmCepAddress);
    await _addBotMessage(
      'Encontrei o endereço:\n'
      '${_upper(address.logradouro)}\n'
      '${address.bairro != null && address.bairro!.isNotEmpty ? '${_upper(address.bairro)}\n' : ''}'
      '${_upper(address.localidade)}\n\n'
      '${ChatBudgetStrings.menuBackOption}',
      type: ChatMessageType.inlineButtons,
      payload: {'actions': ['Confirmar endereço', 'Corrigir endereço']},
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
        'Erro ao buscar dados do PDF: ${fetchResult.error}',
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
    );
    final saveResult = await _pdfRepo.saveInformationEnterprise(updated);
    if (saveResult is Error<void>) {
      await _addBotMessage(
        'Erro ao salvar endereço: ${saveResult.error}',
        type: ChatMessageType.text,
      );
    }
  }

  Future<void> _finishPdfAddressFlow() async {
    _pendingAddress = null;
    _isCorrectingAddress = false;
    _isPdfEditAddressMode = false;

    await _addBotMessage(
      ChatBudgetStrings.pdfEditSuccessAddress,
      type: ChatMessageType.text,
    );
    await _addBotMessage(
      'O que você quer fazer agora?\n\n1. Continuar editando PDF\n2. Voltar ao menu principal',
      type: ChatMessageType.text,
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
      'Endereço cadastrado com sucesso.',
      type: ChatMessageType.text,
    );
    await _addBotMessage(
      _script?.askProducts ?? ChatScriptEntity.fallback.askProducts,
      type: ChatMessageType.action,
      payload: {
        'label': 'Selecionar produtos',
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
        'Informe pelo menos a rua e a cidade.',
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    final fullStreet = number.isNotEmpty ? '$street, $number' : street;

    if (_isPdfEditAddressMode) {
      await _savePdfAddress(
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
      'Endereço cadastrado com sucesso.',
      type: ChatMessageType.text,
    );
    await _addBotMessage(
      _script?.askProducts ?? ChatScriptEntity.fallback.askProducts,
      type: ChatMessageType.action,
      payload: {
        'label': 'Selecionar produtos',
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
      'Endereço cadastrado com sucesso.',
      type: ChatMessageType.text,
    );
    await _addBotMessage(
      _script?.askProducts ?? ChatScriptEntity.fallback.askProducts,
      type: ChatMessageType.action,
      payload: {
        'label': 'Selecionar produtos',
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
      buffer.writeln('Nenhum item no orçamento.');
    } else {
      buffer.writeln('Itens do orçamento:');
      for (final it in items) {
        final lineTotal = it.TOTAL ?? ((it.QTD ?? 0) * (it.PRECO ?? 0));
        grandTotal += lineTotal;
        buffer.writeln(
          '• ${it.DESCRICAO} — ${(it.QTD ?? 1).toInt()}x '
          'R\$ ${(it.PRECO ?? 0).toStringAsFixed(2)} = '
          'R\$ ${lineTotal.toStringAsFixed(2)}',
        );
      }
      buffer.writeln('');
      buffer.writeln('Total: R\$ ${grandTotal.toStringAsFixed(2)}');
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
      'Deseja adicionar algum comentário ou observação ao orçamento?',
      type: ChatMessageType.inlineButtons,
      payload: {'actions': ['SIM', 'NÃO']},
    );

    return Result.ok(null);
  }

  Future<Result<void>> _finalizeAndShare() async {
    final result = await _usecase.finalize();

    if (result is Ok<CustomerInfo>) {
      _setStep(ChatFlowStep.shareLink);
      await _addBotMessage(
        _script?.finalMessage ?? ChatScriptEntity.fallback.finalMessage,
        type: ChatMessageType.action,
        payload: {
          'label': _script?.shareLabel ?? ChatScriptEntity.fallback.shareLabel,
          'action': 'share_link',
        },
      );
    } else {
      await _addBotMessage(
        'Erro ao finalizar o orçamento. Tente novamente.',
        type: ChatMessageType.text,
      );
    }
    return Result.ok(null);
  }

  Future<Result<void>> _shareLink() async {
    final budgetId = _chatRepo.draftBudget?.id;
    if (budgetId == null || budgetId.isEmpty) {
      _shareErrorMessage = 'Orçamento não disponível para compartilhar';
      return Result.error(Exception(_shareErrorMessage));
    }

    final url = await getIt<ShareLinkRepository>().buildShareUrl(
      enderecoNumero: budgetId,
    );
    if (url == null || url.isEmpty) {
      _shareErrorMessage = 'Não foi possível gerar o link. Verifique sua conexão.';
      return Result.error(Exception(_shareErrorMessage));
    }

    _shareErrorMessage = null;
    await SharePlus.instance.share(
      ShareParams(text: url, subject: 'Orçamento'),
    );
    return Result.ok(null);
  }

  Future<Result<void>> _resetChat() async {
    if (_step != ChatFlowStep.shareLink) {
      await _chatRepo.deleteDraft();
    }
    _clearLocalState();
    final step = await _resetToMenuUsecase();
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
    if (!_disposed && (shareLinkCommand.error || shareLinkCommand.completed)) {
      notifyListeners();
    }
  }

  void clearShareError() {
    _shareErrorMessage = null;
    shareLinkCommand.clearResult();
  }

  // ------------------------------------------------------------------
  // Ação de botões inline
  // ------------------------------------------------------------------
  Future<void> handleAction(String action) async {
    switch (action) {
      case 'pick_contact':
        await pickContactCommand.execute();
        break;
      case 'SIM':
        if (_step == ChatFlowStep.askAddress) {
          _setStep(ChatFlowStep.askHasCep);
          await _addBotMessage(
            _script?.askHasCep ?? ChatScriptEntity.fallback.askHasCep,
            type: ChatMessageType.inlineButtons,
            payload: {'actions': ['SIM', 'NÃO']},
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
        streetController.text = _upper(_pendingAddress?.logradouro);
        cityController.text = _upper(_pendingAddress?.localidade);
        neighborhoodController.text = _upper(_pendingAddress?.bairro);
        numberController.clear();
        _setStep(ChatFlowStep.askStreetManual);
        await _addBotMessage(
          _script?.askStreetFallback ?? ChatScriptEntity.fallback.askStreetFallback,
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
        'Produto criado com sucesso! 🎉\n\n'
        'Descrição: $desc\n'
        'Preço: R\$ $preco\n'
        'Categoria: $categoria',
        type: ChatMessageType.inlineButtons,
        payload: {
          'actions': ['Abrir lista de produtos'],
        },
      );
    } else {
      await _addBotMessage(
        'Produto criado com sucesso! 🎉',
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
      'Comentários atualizados com sucesso. Deseja editar '
      'novamente ou finalizar o orçamento?',
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['Editar comentários', 'Finalizar e gerar link']
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

  @override
  void dispose() {
    _disposed = true;
    _chatRepo.removeListener(_onRepoChanged);
    _scriptRepo.removeListener(_onRepoChanged);
    shareLinkCommand.removeListener(_onCommandDone);
    textController.dispose();
    cepController.dispose();
    streetController.dispose();
    numberController.dispose();
    cityController.dispose();
    neighborhoodController.dispose();
    super.dispose();
  }
}
