import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/check_comment_library_access_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/receive_shared_proof_usecase.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/product/domain/usecase/should_ask_segment_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class MainTabViewModel extends ChangeNotifier {
  final ReceiveSharedProofUsecase _receiveShared;
  final PdfRepository _pdfRepository;
  final ShouldAskSegmentUsecase _shouldAskSegment;
  final BudgetRepository _budgets;

  MainTabViewModel(
    this._receiveShared,
    this._pdfRepository,
    this._shouldAskSegment,
    this._budgets,
  ) {
    // Logo trocado em "Editar PDF": o repositório avisa e a barra atualiza.
    _pdfRepository.addListener(loadCompanyLogo);
  }

  /// Logo da empresa (foto do titular), mostrada na barra lateral. `null` =
  /// sem logo cadastrado (ou ainda carregando).
  Uint8List? companyLogo;

  /// Nome da empresa (`EMPRESA` do titular); vazio = ainda sem cadastro.
  String companyName = '';
  bool _loadingLogo = false;

  bool get canUseCommentLibrary => getIt<CheckCommentLibraryAccessUsecase>()();

  /// Orçamento escolhido no modal para abrir o fluxo de recibo; `null` = falhou.
  Future<CustomerInfo?> budgetById(String id) async {
    final result = await _budgets.getBudgetById(id);
    return switch (result) {
      Ok(:final value) when value.id != null => value,
      _ => null,
    };
  }

  Future<void> loadCompanyLogo() async {
    if (_loadingLogo) return;
    _loadingLogo = true;
    try {
      final info = await _pdfRepository.fetchInformationEnterprise();
      if (info is! Ok) return;
      final owner = _pdfRepository.ownerPdf;
      if (owner == null) return;
      final name = (owner.empresa ?? '').trim();
      if (name != companyName) {
        companyName = name;
        notifyListeners();
      }
      final logo = await _pdfRepository.fetchLogo(owner, requireImage: true);
      final bytes = logo is Ok<Uint8List?> ? logo.value : null;
      if (bytes != companyLogo) {
        companyLogo = bytes;
        notifyListeners();
      }
    } finally {
      _loadingLogo = false;
    }
  }

  /// Titular para a tela de editar logo; `null` = sem acesso completo
  /// (a View abre a assinatura). Mesma regra do chat.
  Future<OwnerPdf?> ownerForLogoEdit() async {
    if (!getIt<GetAccessStatusUseCase>().hasFullAccess) return null;
    final result = await _pdfRepository.fetchInformationEnterprise();
    return result is Ok<OwnerPdf> ? result.value : OwnerPdf();
  }

  /// Ainda não perguntamos o ramo de atuação (e não há lista de preço própria).
  Future<bool> shouldAskSegment() => _shouldAskSegment();

  StreamSubscription<SharedProofEvent>? _sharedSub;

  /// Não assinante compartilhou um arquivo → View abre a assinatura.
  bool needsSubscription = false;

  /// Escuta arquivos compartilhados pelo sistema (app aberto e cold start).
  Future<void> listenSharedFiles() async {
    _sharedSub ??= _receiveShared.stream().listen(_onShared);
    final initial = await _receiveShared.initial();
    if (initial != null) _onShared(initial);
  }

  void _onShared(SharedProofEvent event) {
    switch (event) {
      case SharedProofNeedsPremium():
        needsSubscription = true;
      case SharedProofReady():
        openChatRequested = true;
    }
    notifyListeners();
  }

  void consumeNeedsSubscription() => needsSubscription = false;

  @override
  void dispose() {
    _pdfRepository.removeListener(loadCompanyLogo);
    _sharedSub?.cancel();
    super.dispose();
  }

  /// A View abre o chat por cima da Home (compartilhamento ou Home).
  bool openChatRequested = false;

  void consumeOpenChat() => openChatRequested = false;
}
