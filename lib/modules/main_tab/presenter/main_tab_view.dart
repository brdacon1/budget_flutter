import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/presenter/budget_list/budget_list_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/chat_assistant_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_budget_picker/chat_budget_picker_view.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_list/comment_library_list_view.dart';
import 'package:oflite/modules/pdf/presenter/pdf_model_select/presenter/pdf_model_select_view.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/receipt_list_view.dart';
import 'package:oflite/modules/receipt/presenter/receipt_tab/receipt_tab_view.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/dashboard/presenter/dashboard_view.dart';
import 'package:oflite/modules/image/presenter/image_edit_view.dart';
import 'package:oflite/modules/main_tab/presenter/strings/main_tab_pt_string.dart';
import 'package:oflite/modules/home/presenter/home_view.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:oflite/modules/main_tab/presenter/components/main_tab_trial_banner.dart';
import 'package:oflite/modules/product/presenter/product_segment/product_segment_view.dart';

import 'package:oflite/modules/home/presenter/components/home_sub_page.dart';

import 'main_tab_view_model.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabView();
}

class _MainTabView extends State<MainTabView> {
  final MainTabViewModel _viewModel = getIt<MainTabViewModel>();

  @override
  void initState() {
    super.initState();
    // Após o login (auto-login ou manual), a tela principal está pronta e o
    // dono está autenticado: consome um possível orçamento pendente de abrir
    // (caso de cold-start pelo toque no banner da notificação).
    _viewModel.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Comprovantes recebidos pela folha de compartilhamento (§15.4).
      _viewModel.listenSharedFiles();
      _viewModel.loadCompanyLogo();
      // Teste grátis acabou: ao entrar, abre a assinatura (volta = somente
      // leitura dos orçamentos já criados).
      if (getIt<GetAccessStatusUseCase>()() == AccessStatus.expired) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionView()),
        );
      }
      getIt<NotificationRepository>().tryOpenPendingBudget();
      _askSegment();
      // REDUNDÂNCIA de persistência do token FCM: o login já tenta salvar,
      // mas aqui (dashboard) o dono está definitivamente autenticado e o
      // token já foi obtido no startup. Se por algum motivo o save do login
      // não chegou ao Firestore (ex.: race com o `userRepository.selectUser`),
      // esta chamada garante que o token deste device entre na lista
      // `EMPRESAS/{uid}/USERS/{uid}/FCM/{token}`. Idempotente.
      final ownerUid = getIt<UserRepository>().selectUser.value?.user;
      if (ownerUid != null && ownerUid.trim().isNotEmpty) {
        getIt<NotificationRepository>().persistCurrentTokenToFirebase(ownerUid);
      }
    });
  }

  /// Primeira entrada no app: pergunta o ramo e monta a lista de preços inicial.
  /// Fica depois da assinatura expirada (essa rota cobre a tela).
  Future<void> _askSegment() async {
    if (getIt<GetAccessStatusUseCase>()() == AccessStatus.expired) return;
    if (!await _viewModel.shouldAskSegment() || !mounted) return;
    await showProductSegmentBottomModal(context);
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_viewModel.openChatRequested) {
      _viewModel.consumeOpenChat();
      _push(const ChatAssistantView());
    }
    if (!_viewModel.needsSubscription) return;
    _viewModel.consumeNeedsSubscription();
    _push(const SubscriptionView());
  }

  Future<void> _editLogo() async {
    final owner = await _viewModel.ownerForLogoEdit();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                owner == null
                    ? const SubscriptionView()
                    : ImageEditView(
                      owner: owner,
                      title: MainTabStrings.editLogoTitle,
                    ),
      ),
    );
    if (mounted) await _viewModel.loadCompanyLogo();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  /// Primeiro uso, sem orçamento: leva direto à criação de um. Ao concluir,
  /// segue para o que o usuário pediu, já com o orçamento criado escolhido.
  Future<void> _withBudget(Future<void> Function(String? id) next) async {
    if (await _viewModel.hasBudgets()) return next(null);
    if (!mounted) return;
    await _push(const ChatAssistantView(startBudget: true));
    if (!mounted) return;
    final id = await _viewModel.latestBudgetId();
    if (id != null && mounted) await next(id);
  }

  /// Modal de escolha do orçamento (o do chat) → criar recibo direto na tab.
  Future<void> _createReceipt() => _withBudget(_createReceiptFlow);

  Future<void> _createReceiptFlow(String? preselected) async {
    final id = preselected ?? await ChatBudgetPickerView.show(context);
    if (id == null || !mounted) return;
    final budget = await _viewModel.budgetById(id);
    if (budget == null || !mounted) return;
    await _push(
      ReceiptTabView(
        item: budget,
        receipt: const Receipt(
          data: '',
          id: '',
          descricao: 'null',
          valorTotal: 0,
        ),
      ),
    );
  }

  /// Modal de orçamentos → lista de recibos do orçamento escolhido.
  Future<void> _openReceipts() => _withBudget(_openReceiptsFlow);

  Future<void> _openReceiptsFlow(String? preselected) async {
    final id = preselected ?? await ChatBudgetPickerView.show(context);
    if (id == null || !mounted) return;
    final budget = await _viewModel.budgetById(id);
    if (budget == null || !mounted) return;
    await _push(ReceiptListView(item: budget));
  }

  /// Modal de orçamentos → lista só com os orçamentos daquele cliente.
  Future<void> _openClientBudgets() => _withBudget(_openClientBudgetsFlow);

  Future<void> _openClientBudgetsFlow(String? preselected) async {
    final id = preselected ?? await ChatBudgetPickerView.show(context);
    if (id == null || !mounted) return;
    final budget = await _viewModel.budgetById(id);
    if (budget == null || !mounted) return;
    // Com cliente a lista já tem o próprio header com voltar (sem HomeSubPage).
    await _push(BudgetListView(customer: budget));
  }

  /// Lista de comentários cadastrados (mesmo acesso do chat).
  Future<void> _openCommentLibrary() => _push(
    _viewModel.canUseCommentLibrary
        ? const CommentLibraryListView()
        : const SubscriptionView(),
  );

  @override
  Widget build(BuildContext context) {
    // A Home é a única tela da raiz: ela chama as demais (chat, lista de
    // orçamentos, dashboard), que abrem por cima e voltam com "voltar".
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          body: HomeView(
            companyLogo: _viewModel.companyLogo,
            companyName: _viewModel.companyName,
            onEditLogo: _editLogo,
            onOpenChat: () => _push(const ChatAssistantView()),
            onCreateBudget:
                () => _push(const ChatAssistantView(startBudget: true)),
            onOpenBudgets:
                () => _push(const HomeSubPage(child: BudgetListView())),
            onCreateReceipt: _createReceipt,
            onOpenReceipts: _openReceipts,
            onConfigurePdf:
                () => _push(const ChatAssistantView(startPdfEdit: true)),
            onPdfType: () => _push(const PdfModelSelectView()),
            onClientBudgets: _openClientBudgets,
            onSaveComments: _openCommentLibrary,
            onSaveProofs:
                () => _withBudget(
                  (_) => _push(const ChatAssistantView(startProof: true)),
                ),
            onOpenReports:
                () => _push(const HomeSubPage(child: DashboardView())),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [const MainTabTrialBanner()],
            ),
          ),
        );
      },
    );
  }
}
