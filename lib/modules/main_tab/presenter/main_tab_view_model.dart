import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/receive_shared_proof_usecase.dart';

class TabItem {
  final IconData icon;
  final String title;

  TabItem({required this.icon, required this.title});
}

class MainTabViewModel extends ChangeNotifier {
  final ReceiveSharedProofUsecase _receiveShared;

  MainTabViewModel(this._receiveShared);

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
