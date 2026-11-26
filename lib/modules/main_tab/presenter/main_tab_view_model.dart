import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/receive_shared_proof_usecase.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/product/domain/usecase/should_ask_segment_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class TabItem {
  final IconData icon;
  final String title;

  TabItem({required this.icon, required this.title});
}

class MainTabViewModel extends ChangeNotifier {
  final ReceiveSharedProofUsecase _receiveShared;
  final PdfRepository _pdfRepository;
  final ShouldAskSegmentUsecase _shouldAskSegment;

  MainTabViewModel(
    this._receiveShared,
    this._pdfRepository,
    this._shouldAskSegment,
  ) {
    // Logo trocado em "Editar PDF": o repositório avisa e a barra atualiza.
    _pdfRepository.addListener(loadCompanyLogo);
  }

  /// Logo da empresa (foto do titular), mostrada na barra lateral. `null` =
  /// sem logo cadastrado (ou ainda carregando).
  Uint8List? companyLogo;
  bool _loadingLogo = false;

  Future<void> loadCompanyLogo() async {
    if (_loadingLogo) return;
    _loadingLogo = true;
    try {
      final info = await _pdfRepository.fetchInformationEnterprise();
      if (info is! Ok) return;
      final owner = _pdfRepository.ownerPdf;
      if (owner == null) return;
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

  /// Ainda não perguntamos o ramo de atuação (e não há lista de preço própria).
  Future<bool> shouldAskSegment() => _shouldAskSegment();

  StreamSubscription<SharedProofEvent>? _sharedSub;

  /// Muda a cada compartilhamento recebido: recria o chat (que consome os
  /// arquivos pendentes ao iniciar).
  int chatGeneration = 0;

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
        _currentIndex = 0;
        chatGeneration++;
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

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final List<TabItem> _tabItems = [
    TabItem(icon: Icons.support_agent, title: 'Assistente'),
    TabItem(icon: Icons.inventory_outlined, title: 'Orçamentos'),
    TabItem(icon: Icons.dashboard, title: 'Dashboard'),
  ];
  List<TabItem> get tabItems => _tabItems;

  void onTabTapped(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
