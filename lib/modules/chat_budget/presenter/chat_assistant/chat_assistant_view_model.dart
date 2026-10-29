import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
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
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:share_plus/share_plus.dart';

/// Passos do fluxo conversacional.
enum ChatFlowStep {
  idle,
  welcome,
  askClient,
  askPhone,
  askAddress,
  askCep,
  askStreetManual,
  askProducts,
  reviewProducts,
  shareLink,
}

class ChatAssistantViewModel extends ChangeNotifier {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;
  final CreateBudgetFromChatUsecase _usecase;
  final FetchChatScriptUsecase _fetchScriptUsecase;

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
    _step = ChatFlowStep.welcome;
    _pendingClientName = '';
    _pendingPhone = '';
    _shareErrorMessage = null;

    // Carrega script
    final scriptResult = await _fetchScriptUsecase.call();
    if (scriptResult is Error<ChatScriptEntity>) {
      return Result.error(scriptResult.error);
    }

    // Mensagem de boas-vindas
    await _addBotMessage(
      _script?.welcomeMessage ?? ChatScriptEntity.fallback.welcomeMessage,
      type: ChatMessageType.text,
    );

    // Pergunta nome do cliente
    await _addBotMessage(
      _script?.askClientName ?? ChatScriptEntity.fallback.askClientName,
      type: ChatMessageType.contactPicker,
    );
    _step = ChatFlowStep.askClient;
    return Result.ok(null);
  }

  // ------------------------------------------------------------------
  // Ações do usuário
  // ------------------------------------------------------------------

  Future<Result<void>> _sendText(String text) async {
    if (text.trim().isEmpty) return Result.ok(null);
    final clean = text.trim();

    // Adiciona mensagem do usuário
    await _addUserMessage(clean);

    switch (_step) {
      case ChatFlowStep.welcome:
      case ChatFlowStep.askClient:
        // Guarda nome e pede telefone
        _pendingClientName = clean;
        _step = ChatFlowStep.askPhone;
        await _addBotMessage(
          _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
          type: ChatMessageType.text,
        );
        break;

      case ChatFlowStep.askPhone:
        // Recebe telefone e cria orçamento
        _pendingPhone = _phoneMask.maskText(clean);
        await _createDraftAndGoToAddress(
          _pendingClientName,
          phone: _pendingPhone,
        );
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
      final hasPermission = await FlutterContactPicker.requestPermission();
      if (!hasPermission) return Result.ok(null);

      final contact = await FlutterContactPicker.pickFullContact();

      // Extrai nome
      String name = 'Cliente';
      if (contact.name != null) {
        final nick = contact.name?.nickName ?? '';
        if (nick.isNotEmpty) {
          name = nick;
        } else {
          final first = contact.name?.firstName ?? '';
          final last = contact.name?.lastName ?? '';
          name = '$first $last'.trim();
          if (name.isEmpty) name = 'Cliente';
        }
      }

      // Extrai telefone
      String? phone;
      final phones = contact.phones;
      if (phones != null && phones.isNotEmpty) {
        phone = phones.first.number
            ?.replaceAll('+55', '')
            .replaceAll('+', '')
            .replaceAll(RegExp(r'\D'), '');
        if (phone != null && phone.isNotEmpty) {
          phone = _phoneMask.maskText(phone);
        }
      }

      await _addUserMessage(name);

      // Se não tiver telefone no contato, pede
      if (phone == null || phone.isEmpty) {
        _pendingClientName = name;
        _step = ChatFlowStep.askPhone;
        await _addBotMessage(
          _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
          type: ChatMessageType.text,
        );
        return Result.ok(null);
      }

      return await _createDraftAndGoToAddress(name, phone: phone);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  Future<Result<void>> _createDraftFromName() async {
    final name = textController.text.trim();
    if (name.isEmpty) return Result.ok(null);
    textController.clear();
    await _addUserMessage(name);

    _pendingClientName = name;
    _step = ChatFlowStep.askPhone;
    await _addBotMessage(
      _script?.askPhone ?? ChatScriptEntity.fallback.askPhone,
      type: ChatMessageType.text,
    );
    return Result.ok(null);
  }

  /// Cria o orçamento e avança para perguntar o endereço.
  Future<Result<void>> _createDraftAndGoToAddress(
    String clientName, {
    String? phone,
  }) async {
    final result = await _usecase.createDraft(clientName, phone: phone);

    if (result is Ok<CustomerInfo>) {
      _step = ChatFlowStep.askAddress;
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
    _step = ChatFlowStep.askProducts;
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

  Future<Result<void>> _submitCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) {
      await _addBotMessage(
        'CEP inválido. Digite 8 números ou pule.',
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    final viaCep = ViaCepService();
    final address = await viaCep.getAdress(cep);

    if (address.logradouro == null || address.logradouro!.isEmpty) {
      // Não encontrou CEP, pede dados manuais
      _step = ChatFlowStep.askStreetManual;
      await _addBotMessage(
        _script?.askStreetFallback ??
            ChatScriptEntity.fallback.askStreetFallback,
        type: ChatMessageType.text,
      );
      return Result.ok(null);
    }

    // Atualiza endereço via CEP
    await _usecase.updateAddress(
      zip: cep,
      street: address.logradouro,
      city: address.localidade,
      neighborhood: address.bairro,
    );

    _step = ChatFlowStep.askProducts;
    await _addBotMessage(
      'Endereço cadastrado: ${address.logradouro}, ${address.bairro}, ${address.localidade}.',
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

    _step = ChatFlowStep.askProducts;
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

    // Monta resumo
    final buffer = StringBuffer();
    buffer.writeln('Produtos selecionados:');
    for (final it in items) {
      buffer.writeln(
          '• ${it.DESCRICAO} — ${it.QTD?.toInt() ?? 1}x R\$ ${(it.PRECO ?? 0).toStringAsFixed(2)}');
    }

    _step = ChatFlowStep.reviewProducts;
    await _addBotMessage(
      buffer.toString(),
      type: ChatMessageType.productList,
    );

    // Finaliza e mostra link
    return await _finalizeAndShare();
  }

  Future<Result<void>> _editProducts(List<ItemsBudget> items) async {
    return _confirmProducts(items, isEdit: true);
  }

  Future<Result<void>> _finalizeAndShare() async {
    final result = await _usecase.finalize();

    if (result is Ok<CustomerInfo>) {
      _step = ChatFlowStep.shareLink;
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
    _chatRepo.clearSession();
    _currentDraftItems.clear();
    _pendingClientName = '';
    _pendingPhone = '';
    _shareErrorMessage = null;
    textController.clear();
    cepController.clear();
    streetController.clear();
    cityController.clear();
    neighborhoodController.clear();
    _step = ChatFlowStep.idle;
    return await _initialize();
  }

  // ------------------------------------------------------------------
  // Helpers de mensagens
  // ------------------------------------------------------------------

  Future<void> _addBotMessage(
    String text, {
    ChatMessageType type = ChatMessageType.text,
    Map<String, dynamic>? payload,
  }) async {
    final msg = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: ChatSender.bot,
      type: type,
      content: text,
      payload: payload,
      timestamp: DateTime.now(),
    );
    await _chatRepo.sendMessage(msg);
  }

  Future<void> _addUserMessage(String text) async {
    final msg = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: ChatSender.user,
      type: ChatMessageType.text,
      content: text,
      timestamp: DateTime.now(),
    );
    await _chatRepo.sendMessage(msg);
  }

  Future<Result<void>> _noop() async => Result.ok(null);

  void _onRepoChanged() => notifyListeners();

  void _onCommandDone() {
    // Quando o comando termina (sucesso ou erro), notifica a View
    // para que ela possa reagir (ex: mostrar SnackBar de erro).
    if (shareLinkCommand.error || shareLinkCommand.completed) {
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
        _step = ChatFlowStep.askCep;
        await _addBotMessage(
          _script?.askCep ?? ChatScriptEntity.fallback.askCep,
          type: ChatMessageType.text,
        );
        break;
      case 'NÃO':
        await skipAddressCommand.execute();
        break;
      case 'open_products':
        // A view abre a tela de produtos
        break;
      case 'share_link':
        await shareLinkCommand.execute();
        break;
      case 'edit_products':
        // A view abre a tela de produtos em modo edição
        break;
    }
  }

  @override
  void dispose() {
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
