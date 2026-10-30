import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as UserInfo;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_script_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/fetch_chat_script_usecase.dart';
import 'package:oflite/modules/core/services/data/service/budget_share_link_service.dart';
import 'package:oflite/modules/core/services/data/service/via_cep_service.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/shared/models/address.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:share_plus/share_plus.dart';

/// Passos do fluxo conversacional.
enum ChatFlowStep {
  idle,
  welcome,
  askClient,
  askPhone,
  confirmClientData,
  askAddress,
  askHasCep,
  askCep,
  confirmCepAddress,
  askStreetManual,
  askProducts,
  reviewProducts,
  askComments,
  shareLink,
}

class ChatAssistantViewModel extends ChangeNotifier {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;
  final CreateBudgetFromChatUsecase _usecase;
  final FetchChatScriptUsecase _fetchScriptUsecase;

  bool _disposed = false;

  ChatAssistantViewModel(
    this._chatRepo,
    this._scriptRepo,
    this._usecase,
    this._fetchScriptUsecase,
  ) {
    _chatRepo.addListener(_onRepoChanged);
    _scriptRepo.addListener(_onRepoChanged);
    shareLinkCommand.addListener(_onCommandDone);
  }

  // ------------------------------------------------------------------
  // Estado observável
  // ------------------------------------------------------------------
  ChatFlowStep _step = ChatFlowStep.idle;
  ChatFlowStep get step => _step;

  void _setStep(ChatFlowStep value) {
    _step = value;
    _chatRepo.setCurrentFlowStep(value.name);
  }

  List<ChatMessageEntity> get messages => _chatRepo.messages;

  CustomerInfo? get draftBudget => _chatRepo.draftBudget;

  ChatScriptEntity? get _script => _scriptRepo.currentScript;

  bool get isLoading => initializeChat.running || sendTextCommand.running;

  /// Mensagem de erro do último share (para a View exibir).
  String? get shareErrorMessage => _shareErrorMessage;
  String? _shareErrorMessage;

  // Controllers para inputs
  final textController = TextEditingController();
  final cepController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final neighborhoodController = TextEditingController();

  // Armazena dados temporários enquanto o usuário responde passo a passo
  String _pendingClientName = '';
  String _pendingPhone = '';

  // IDs das mensagens de nome e telefone para permitir edição
  String? _clientNameMsgId;
  String? _clientPhoneMsgId;

  // Flag de edição inline (mensagem específica sendo editada)
  String? _editingMsgId;   // id da mensagem que está sendo editada
  String? _editingField;    // 'clientName' | 'clientPhone'

  bool get isEditingMessage => _editingMsgId != null;

  // IDs das mensagens de review e pergunta de comentários
  // (permitem remover/re-enviar quando o usuário edita produtos).
  String? _reviewMsgId;
  String? _commentQuestionMsgId;

  // ID da mensagem de feedback após edição de comentários.
  // Evita duplicar o balão "Comentários atualizados..." quando o usuário
  // edita comentários, volta, edita de novo e volta novamente.
  String? _commentsFeedbackMsgId;

  // Endereço retornado pelo ViaCEP, aguardando confirmação do usuário
  Address? _pendingAddress;

  // Itens atualmente no rascunho (para permitir edição).
  final List<ItemsBudget> _currentDraftItems = [];

  // Máscara de telefone
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // ------------------------------------------------------------------
  // Commands
  // ------------------------------------------------------------------
  late final Command0<void> initializeChat = Command0(_initialize);
  late final Command1<void, String> sendTextCommand = Command1(_sendText);
  late final Command0<void> pickContactCommand = Command0(_pickContact);
  late final Command0<void> createDraftCommand = Command0(_createDraftFromName);
  late final Command0<void> skipAddressCommand = Command0(_skipAddress);
  late final Command1<void, String> submitCepCommand = Command1(_submitCep);
  late final Command0<void> confirmCepAddressCommand = Command0(_confirmCepAddress);
  late final Command0<void> submitManualAddressCommand =
      Command0(_submitManualAddress);
  late final Command0<void> openProductSelectionCommand = Command0(_noop);
  late final Command1<void, List<ItemsBudget>> confirmProductsCommand =
      Command1(_confirmProducts);
  late final Command1<void, List<ItemsBudget>> editProductsCommand =
      Command1(_editProducts);
  late final Command0<void> shareLinkCommand = Command0(_shareLink);
  late final Command0<void> resetChatCommand = Command0(_resetChat);

  // ------------------------------------------------------------------
  // Inicialização
  // ------------------------------------------------------------------
  Future<Result<void>> _initialize() async {
    final saved = _chatRepo.currentFlowStep;

    // Se a conversa anterior já foi finalizada (link compartilhado),
    // limpa tudo e inicia uma nova conversa do zero.
    if (saved == ChatFlowStep.shareLink.name) {
      // Conversa já finalizada: limpa apenas o estado LOCAL do chat.
      // NÃO deleta o orçamento do banco — ele já existe para o cliente.
      _clientNameMsgId = null;
      _clientPhoneMsgId = null;
      _editingMsgId = null;
      _editingField = null;
      _chatRepo.clearSession();
      _chatRepo.setCurrentFlowStep(null);
      _currentDraftItems.clear();
      _pendingClientName = '';
      _pendingPhone = '';
      _pendingAddress = null;
      _shareErrorMessage = null;
      textController.clear();
      cepController.clear();
      streetController.clear();
      cityController.clear();
      neighborhoodController.clear();
      _step = ChatFlowStep.idle;
      // cai no fluxo de inicialização abaixo
    } else if (_chatRepo.messages.isNotEmpty && saved != null) {
      // Restaura conversa em andamento sem duplicar mensagens
      _step = ChatFlowStep.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ChatFlowStep.askClient,
      );
      notifyListeners();
      return Result.ok(null);
    }

    _setStep(ChatFlowStep.welcome);
    _pendingClientName = '';
    _pendingPhone = '';
    _pendingAddress = null;
    _shareErrorMessage = null;
    _clientNameMsgId = null;
    _clientPhoneMsgId = null;
    _editingMsgId = null;
    _editingField = null;

    // Carrega script
    final scriptResult = await _fetchScriptUsecase.call();
    if (scriptResult is Error<ChatScriptEntity>) {
      return Result.error(scriptResult.error);
    }

    // Mensagem inicial com boas-vindas + botão de escolher contato em um só balão
    _setStep(ChatFlowStep.askClient);
    await _addBotMessage(
      _script?.welcomeMessage ?? ChatScriptEntity.fallback.welcomeMessage,
      type: ChatMessageType.contactPicker,
    );
    return Result.ok(null);
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

  /// Retorna texto formatado ou vazio se inválido
  String? _tryFormatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) return null;
    return _phoneMask.maskText(digits);
  }

  // ------------------------------------------------------------------
  // Ações do usuário
  // ------------------------------------------------------------------

  Future<Result<void>> _sendText(String text) async {
    if (text.trim().isEmpty) return Result.ok(null);
    final clean = text.trim();

    // ----------------------------------------------------------------
    // MODO EDIÇÃO: atualiza a mensagem existente SEM criar nova
    // ----------------------------------------------------------------
    if (_editingMsgId != null && _editingField != null) {
      await _chatRepo.updateMessage(_editingMsgId!, clean);

      if (_editingField == 'clientName') {
        _pendingClientName = clean;
        // atualiza referência se o ID mudou (não muda, é o mesmo)
      } else if (_editingField == 'clientPhone') {
        final formatted = _tryFormatPhone(clean);
        if (formatted != null) {
          _pendingPhone = formatted;
        } else {
          _pendingPhone = clean;
        }
      }

      textController.clear();
      _editingMsgId = null;
      _editingField = null;
      notifyListeners();
      return Result.ok(null);
    }

    // ---------------------------------------------------------------
    // FLUXO NORMAL: envia nova mensagem do usuário
    // ---------------------------------------------------------------
    final msgId = _generateMessageId();
    final userPayload = switch (_step) {
      ChatFlowStep.askClient => {'editableField': 'clientName'},
      ChatFlowStep.askPhone => {'editableField': 'clientPhone'},
      _ => null,
    };
    await _sendUserMessageWithId(msgId, clean, payload: userPayload);

    // Guarda ID da mensagem para edição futura
    if (_step == ChatFlowStep.askClient) {
      _clientNameMsgId = msgId;
    } else if (_step == ChatFlowStep.askPhone) {
      _clientPhoneMsgId = msgId;
    }

    switch (_step) {
      case ChatFlowStep.welcome:
      case ChatFlowStep.askClient:
        // Guarda nome e pede telefone
        _pendingClientName = clean;
        _setStep(ChatFlowStep.askPhone);
        await _addBotMessage(
          _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
          type: ChatMessageType.text,
        );
        break;

      case ChatFlowStep.askPhone:
        // Valida telefone obrigatório
        if (!_isValidPhone(clean)) {
          await _addBotMessage(
            'Telefone inválido. Informe apenas números com DDD. Ex: (11) 99999-9999 ou 11999999999.',
            type: ChatMessageType.text,
          );
          // Permanece no mesmo step pedindo telefone novamente
          break;
        }
        _pendingPhone = _normalizePhone(clean);
        await _showClientDataConfirmation();
        break;

      case ChatFlowStep.askCep:
        await _submitCep(clean);
        break;

      case ChatFlowStep.askStreetManual:
        // Input dedicado, não chega aqui
        break;

      default:
        break;
    }
    return Result.ok(null);
  }

  Future<Result<void>> _pickContact() async {
    try {
      final hasPermission = await UserInfo.FlutterContacts.requestPermission();
      if (!hasPermission) return Result.ok(null);

      final contact = await UserInfo.FlutterContacts.openExternalPick();
      if (contact == null) return Result.ok(null);

      // Extrai nome
      String name = contact.displayName.trim();
      if (name.isEmpty) {
        final first = contact.name.first.trim();
        final last = contact.name.last.trim();
        name = '$first $last'.trim();
      }
      if (name.isEmpty) name = 'Cliente';

      // Extrai telefone
      String? phone;
      final phones = contact.phones;
      if (phones.isNotEmpty) {
        phone = phones.first.number
            .replaceAll('+55', '')
            .replaceAll('+', '')
            .replaceAll(RegExp(r'\D'), '');
        if (phone.isNotEmpty) {
          // valida quantidade de dígitos
          if (phone.length < 10 || phone.length > 11) {
            phone = null; // inválido, vai pedir manualmente
          } else {
            phone = _phoneMask.maskText(phone);
          }
        }
      }

      final nameMsgId = _generateMessageId();
      await _sendUserMessageWithId(nameMsgId, name, payload: {'editableField': 'clientName'});
      _clientNameMsgId = nameMsgId;
      _pendingClientName = name;

      // Se não tiver telefone válido no contato, pede
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
    await _sendUserMessageWithId(msgId, name, payload: {'editableField': 'clientName'});
    _clientNameMsgId = msgId;

    _pendingClientName = name;
    _setStep(ChatFlowStep.askPhone);
    await _addBotMessage(
      _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
      type: ChatMessageType.text,
    );
    return Result.ok(null);
  }

  /// Mostra os dados do cliente para confirmação antes de criar o rascunho.
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

  /// Prepara modo de edição inline (tipo WhatsApp).
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

  /// Cancela o modo de edição (ex: ao tocar fora)
  void cancelEdit() {
    _editingMsgId = null;
    _editingField = null;
    textController.clear();
    notifyListeners();
  }

  /// Cria o orçamento e avança para perguntar o endereço.
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

  /// Usuário respondeu "SIM" em "Você tem o CEP?" → pede o CEP.
  Future<Result<void>> _askForCep() async {
    _setStep(ChatFlowStep.askCep);
    await _addBotMessage(
      _script?.askCep ?? ChatScriptEntity.fallback.askCep,
      type: ChatMessageType.text,
    );
    return Result.ok(null);
  }

  /// Usuário respondeu "NÃO" em "Você tem o CEP?" → vai para manual.
  Future<Result<void>> _goToManualAddress() async {
    _setStep(ChatFlowStep.askStreetManual);
    await _addBotMessage(
      _script?.askStreetFallback ?? ChatScriptEntity.fallback.askStreetFallback,
      type: ChatMessageType.text,
    );
    return Result.ok(null);
  }

  Future<Result<void>> _submitCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) {
      await _addBotMessage(
        'CEP inválido. Digite 8 números.',
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    final viaCep = ViaCepService();
    final address = await viaCep.getAdress(cep);

    if (address.logradouro == null || address.logradouro!.isEmpty) {
      // CEP não encontrado → avisa e vai para manual
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

    // Guarda o endereço encontrado e espera confirmação
    _pendingAddress = address;
    _pendingAddress!.cep = cep;

    _setStep(ChatFlowStep.confirmCepAddress);
    await _addBotMessage(
      'Encontrei o endereço:\n'
      '${address.logradouro}\n'
      '${address.bairro != null && address.bairro!.isNotEmpty ? '${address.bairro}\n' : ''}'
      '${address.localidade}',
      type: ChatMessageType.inlineButtons,
      payload: {'actions': ['Confirmar endereço', 'Corrigir endereço']},
    );
    return Result.ok(null);
  }

  /// Usuário confirmou o endereço retornado pelo ViaCEP.
  Future<Result<void>> _confirmCepAddress() async {
    if (_pendingAddress == null) return Result.ok(null);

    await _usecase.updateAddress(
      zip: _pendingAddress!.cep,
      street: _pendingAddress!.logradouro,
      city: _pendingAddress!.localidade,
      neighborhood: _pendingAddress!.bairro,
    );

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

  Future<Result<void>> _submitManualAddress() async {
    final street = streetController.text.trim();
    final city = cityController.text.trim();
    final neighborhood = neighborhoodController.text.trim();

    if (street.isEmpty || city.isEmpty) {
      await _addBotMessage(
        'Informe pelo menos a rua e a cidade.',
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    await _usecase.updateAddress(
      street: street,
      city: city,
      neighborhood: neighborhood.isEmpty ? null : neighborhood,
    );

    streetController.clear();
    cityController.clear();
    neighborhoodController.clear();

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

    // Mostra resumo atualizado com os itens do banco
    return await _showProductReviewAndComments();
  }

  Future<Result<void>> _editProducts(List<ItemsBudget> items) async {
    return _confirmProducts(items, isEdit: true);
  }

  /// Busca os itens atuais do draft no banco e exibe o resumo + pergunta comentários.
  /// Remove as mensagens anteriores para evitar duplicação no chat.
  Future<Result<void>> _showProductReviewAndComments() async {
    // Remove mensagens anteriores de review e comentários (já exibidas)
    if (_reviewMsgId != null) {
      await _chatRepo.removeMessageById(_reviewMsgId!);
      _reviewMsgId = null;
    }
    if (_commentQuestionMsgId != null) {
      await _chatRepo.removeMessageById(_commentQuestionMsgId!);
      _commentQuestionMsgId = null;
    }

    // Busca itens atualizados do draft
    final result = await _chatRepo.fetchDraftItems();
    final List<ItemsBudget> items;
    if (result is Ok<List<ItemsBudget>>) {
      items = result.value;
    } else {
      items = List<ItemsBudget>.from(_currentDraftItems);
    }

    // Monta resumo
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
          '• ${it.DESCRICAO} — ${(it.QTD ?? 1).toInt()}x R\$ ${(it.PRECO ?? 0).toStringAsFixed(2)} = R\$ ${lineTotal.toStringAsFixed(2)}',
        );
      }
      buffer.writeln('');
      buffer.writeln('Total: R\$ ${grandTotal.toStringAsFixed(2)}');
    }

    _setStep(ChatFlowStep.askComments);

    // Envia resumo e guarda ID
    _reviewMsgId = _generateMessageId();
    await _sendBotMessageWithId(
      _reviewMsgId!,
      buffer.toString(),
      type: ChatMessageType.productList,
    );

    // Envia pergunta de comentários e guarda ID
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

    final url = await BudgetShareLinkService.buildShareUrl(
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
    // Se a conversa já foi finalizada (shareLink), apaga apenas estado LOCAL.
    // NÃO deleta o orçamento do banco — ele já é um orçamento válido e salvo
    // para o cliente.
    if (_step != ChatFlowStep.shareLink) {
      await _chatRepo.deleteDraft();
    }
    _chatRepo.clearSession();
    _currentDraftItems.clear();
    _pendingClientName = '';
    _pendingPhone = '';
    _pendingAddress = null;
    _shareErrorMessage = null;
    textController.clear();
    cepController.clear();
    streetController.clear();
    cityController.clear();
    neighborhoodController.clear();
    _clientNameMsgId = null;
    _clientPhoneMsgId = null;
    _editingMsgId = null;
    _editingField = null;
    _reviewMsgId = null;
    _commentQuestionMsgId = null;
    _commentsFeedbackMsgId = null;
    _chatRepo.setCurrentFlowStep(null);
    _step = ChatFlowStep.idle;
    return await _initialize();
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

  /// Limpa o erro de share para que o SnackBar não reapareça.
  void clearShareError() {
    _shareErrorMessage = null;
    shareLinkCommand.clearResult();
  }

  // ------------------------------------------------------------------
  // Ação de botões inline recebida pela View
  // ------------------------------------------------------------------

  Future<void> handleAction(String action) async {
    switch (action) {
      case 'pick_contact':
        await pickContactCommand.execute();
        break;
      case 'SIM':
        if (_step == ChatFlowStep.askAddress) {
          // SIM para "quer incluir endereço?" → pergunta se tem CEP
          _setStep(ChatFlowStep.askHasCep);
          await _addBotMessage(
            _script?.askHasCep ?? ChatScriptEntity.fallback.askHasCep,
            type: ChatMessageType.inlineButtons,
            payload: {'actions': ['SIM', 'NÃO']},
          );
        } else if (_step == ChatFlowStep.askHasCep) {
          // SIM tem CEP → pede o CEP
          await _askForCep();
        } else if (_step == ChatFlowStep.askComments) {
          // SIM quer comentários → view abre tela de comentários
          // Ação é tratada pela View via onAction
        }
        break;
      case 'NÃO':
        if (_step == ChatFlowStep.askAddress) {
          // NÃO quer endereço → pula
          await skipAddressCommand.execute();
        } else if (_step == ChatFlowStep.askHasCep) {
          // NÃO tem CEP → vai para manual
          await _goToManualAddress();
        } else if (_step == ChatFlowStep.askComments) {
          // NÃO quer comentários → pula e finaliza
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
        // Limpa endereço pendente e vai para manual
        _pendingAddress = null;
        await _goToManualAddress();
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
        // A view abre a tela de produtos
        break;
      case 'share_link':
        await shareLinkCommand.execute();
        break;
      case 'finalize_budget':
        await _finalizeAndShare();
        break;
      case 'edit_products':
        // A view abre a tela de produtos em modo edição
        break;
    }
  }

  /// Chamado pela View após o usuário voltar da tela de itens do orçamento.
  Future<void> goToCommentsAfterProductEdit() async {
    // Sincroniza o total recalculado pela BudgetListItemsViewModel
    await _chatRepo.refreshDraftTotal();
    // Mostra resumo atualizado e pergunta de comentários
    await _showProductReviewAndComments();
  }

  /// Chamado pela View após o usuário voltar da tela de comentários.
  /// Envia o feedback de comentários atualizados com botões de ação,
  /// mas garante que não haja duplicatas se o balão já existe.
  Future<void> finalizeAfterComments() async {
    _setStep(ChatFlowStep.askComments);

    // Se o balão de feedback já foi enviado anteriormente e ainda existe
    // no histórico, simplesmente mantém a mensagem atual — não repete.
    if (_commentsFeedbackMsgId != null &&
        _chatRepo.messages.any((m) => m.id == _commentsFeedbackMsgId)) {
      return;
    }

    final msgId = _generateMessageId();
    _commentsFeedbackMsgId = msgId;

    await _sendBotMessageWithId(
      msgId,
      'Comentários atualizados com sucesso. Deseja editar novamente ou finalizar o orçamento?',
      type: ChatMessageType.inlineButtons,
      payload: {
        'actions': ['Editar comentários', 'Finalizar e gerar link']
      },
    );
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
    cityController.dispose();
    neighborhoodController.dispose();
    super.dispose();
  }
}
