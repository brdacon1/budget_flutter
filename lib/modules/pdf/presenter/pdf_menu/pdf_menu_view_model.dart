import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_list/budget_comment_list_view.dart';
import 'package:oflite/modules/budget/presenter/budget_list/budget_list_view.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/budget_metrics_view.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/entity/pdf_layout_type.dart';
import 'package:oflite/modules/pdf/presenter/pdf_budget/pdf_budget_view.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/receipt_list_view.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/check_ai_access_usecase.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_list/payment_proof_list_view.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/widgets/modals/ads_option_bottom_modal_widget.dart';
import 'package:share_plus/share_plus.dart';

/// Ação de cada item do menu Mais (a posição na lista não importa).
enum PdfMenuOption {
  customerBudgets,
  metrics,
  comments,
  receipt,
  shareLink,
  pdfExecutive,
  pdfProfessional,
  proofs,
}

/// Agrupamento visual dos itens do menu.
enum PdfMenuSection { budget, share, finance }

class MenuItem {
  final PdfMenuOption option;
  final PdfMenuSection section;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const MenuItem({
    required this.option,
    required this.section,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class PdfMenuViewModel extends ChangeNotifier {
  final DisplayAlertRepository _displayAlert;
  final ShareLinkRepository _shareLinkRepository;
  final CustomerInfo item;
  final bool showCustomerBudgets;

  List<MenuItem> menuItems = <MenuItem>[];

  PdfMenuViewModel({
    required this.item,
    this.showCustomerBudgets = true,
    DisplayAlertRepository? displayAlertRepository,
    ShareLinkRepository? shareLinkRepository,
  }) : _displayAlert =
           displayAlertRepository ?? getIt<DisplayAlertRepository>(),
       _shareLinkRepository =
           shareLinkRepository ?? getIt<ShareLinkRepository>();

  Future<void> inicialData() async {
    menuItems = <MenuItem>[
      if (showCustomerBudgets)
        MenuItem(
          option: PdfMenuOption.customerBudgets,
          section: PdfMenuSection.budget,
          icon: Icons.folder_shared_outlined,
          color: const Color(0xFF2697FF),
          title: PdfStrings.menuCustomerBudgets,
          subtitle: PdfStrings.menuCustomerBudgetsDesc,
        ),
      MenuItem(
        option: PdfMenuOption.metrics,
        section: PdfMenuSection.budget,
        icon: Icons.insights_outlined,
        color: const Color(0xFF2ED573),
        title: PdfStrings.menuMetrics,
        subtitle: PdfStrings.menuMetricsDesc,
      ),
      MenuItem(
        option: PdfMenuOption.comments,
        section: PdfMenuSection.budget,
        icon: Icons.comment_outlined,
        color: const Color(0xFFFFB800),
        title: PdfStrings.menuComments,
        subtitle: PdfStrings.menuCommentsDesc,
      ),
      MenuItem(
        option: PdfMenuOption.shareLink,
        section: PdfMenuSection.share,
        icon: Icons.share_outlined,
        color: const Color(0xFF0DF5E4),
        title: PdfStrings.menuShareLink,
        subtitle: PdfStrings.menuShareLinkDesc,
      ),
      MenuItem(
        option: PdfMenuOption.pdfExecutive,
        section: PdfMenuSection.share,
        icon: Icons.business_center_outlined,
        color: const Color(0xFFB388FF),
        title: PdfStrings.menuPdfExecutive,
        subtitle: PdfStrings.menuPdfExecutiveDesc,
      ),
      MenuItem(
        option: PdfMenuOption.pdfProfessional,
        section: PdfMenuSection.share,
        icon: Icons.workspace_premium_outlined,
        color: const Color(0xFFFF9F43),
        title: PdfStrings.menuPdfProfessional,
        subtitle: PdfStrings.menuPdfProfessionalDesc,
      ),
      MenuItem(
        option: PdfMenuOption.receipt,
        section: PdfMenuSection.finance,
        icon: Icons.payments_outlined,
        color: const Color(0xFF00BFA5),
        title: PdfStrings.menuReceipt,
        subtitle: PdfStrings.menuReceiptDesc,
      ),
      // Comprovantes: só assinantes (mesmo gate do chat com IA).
      if (getIt<CheckAiAccessUsecase>()())
        MenuItem(
          option: PdfMenuOption.proofs,
          section: PdfMenuSection.finance,
          icon: Icons.attach_file_rounded,
          color: const Color(0xFFFF6B9D),
          title: PaymentProofStrings.menuLabel,
          subtitle: PdfStrings.menuProofsDesc,
        ),
    ];
    notifyListeners();
  }

  Future<void> refresh() => inicialData();

  Future<void> openOption(BuildContext context, int index) async {
    switch (menuItems[index].option) {
      case PdfMenuOption.customerBudgets:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetListView(customer: item),
          ),
        );
        break;
      case PdfMenuOption.metrics:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetMetricsView(item: item),
          ),
        );
        break;
      case PdfMenuOption.comments:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetCommentListView(item: item),
          ),
        );
        break;
      case PdfMenuOption.receipt:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceiptListView(item: item)),
        );
        break;
      case PdfMenuOption.proofs:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentProofListView(item: item),
          ),
        );
        break;
      case PdfMenuOption.pdfExecutive:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const PdfBudgetView(layoutType: PdfLayoutType.executive),
          ),
        );
        break;
      case PdfMenuOption.pdfProfessional:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const PdfBudgetView(layoutType: PdfLayoutType.professional),
          ),
        );
        break;
      case PdfMenuOption.shareLink:
        if (!(getIt<UserRepository>().selectUser.value?.autoRenewing ??
            false)) {
          await _displayAlert
              .adsNotification(context)
              .then(
                (value) async => {
                  if (value == PdfStrings.watchAd)
                    {
                      await shareBudget(context),
                      Future.delayed(const Duration(milliseconds: 2), () {
                        getIt<AdsRepository>().showInterstitial();
                      }),
                    }
                  else if (value == PdfStrings.goPremium)
                    {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionView(),
                        ),
                      ),
                    },
                },
              );
        } else {
          await shareBudget(context);
        }
        break;
    }
    await inicialData();
  }

  Future<String> adsNotification(BuildContext context) async {
    String resultText = '';
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdsOptionBottomModalWidget(),
    ).then((value) {
      resultText = value ?? '';
    });
    return resultText;
  }

  /// Gera o link público Web do orçamento (número do endereço + token
  /// provisório do Firebase) e abre a sheet nativa de compartilhamento.
  ///
  /// Reutiliza `BudgetShareLinkService` (aditivo, sem alterar regras do app
  /// mobile). O `id` do orçamento (`CustomerInfo.id`) é o "número do
  /// endereço" usado para localizá-lo no fluxo Web — nunca o telefone.
  Future<void> shareBudget(BuildContext context) async {
    final enderecoNumero = item.id;
    if (enderecoNumero == null || enderecoNumero.isEmpty) {
      await _displayAlert.notificationWarning(
        context,
        PdfStrings.notYet,
        PdfStrings.saveBeforeShare,
      );
      return;
    }

    try {
      final url = await _shareLinkRepository.buildShareUrl(
        enderecoNumero: enderecoNumero,
      );
      if (url == null) {
        if (!context.mounted) return;
        await _displayAlert.notificationError(
          context,
          PdfStrings.errorTitle,
          PdfStrings.errorGenerateLink,
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(text: url, subject: PdfStrings.pdfTitle),
      );
    } catch (_) {
      if (context.mounted) {
        await _displayAlert.notificationError(
          context,
          PdfStrings.errorTitle,
          PdfStrings.errorShareLink,
        );
      }
    }
  }
}
