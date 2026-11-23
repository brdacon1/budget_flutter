import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/check_ai_access_usecase.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:share_plus/share_plus.dart';

/// Ação de cada opção da tela (a posição na lista não importa).
enum BudgetOptionType {
  customerBudgets,
  metrics,
  comments,
  receipt,
  shareLink,
  pdfExecutive,
  pdfProfessional,
  proofs,
}

/// Agrupamento visual das opções.
enum BudgetOptionSection { budget, share, finance }

class BudgetOption {
  final BudgetOptionType type;
  final BudgetOptionSection section;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const BudgetOption({
    required this.type,
    required this.section,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

/// Falha do compartilhamento de link; [isWarning] = aviso (não é erro).
class BudgetShareException implements Exception {
  final String title;
  final String message;
  final bool isWarning;

  const BudgetShareException(
    this.title,
    this.message, {
    this.isWarning = false,
  });
}

class BudgetOptionsViewModel extends ChangeNotifier {
  final ShareLinkRepository _shareLinkRepository;
  final UserRepository _userRepository;
  final CheckAiAccessUsecase _checkAiAccess;
  final CustomerInfo item;
  final bool showCustomerBudgets;

  late final Command0<void> shareCommand;

  BudgetOptionsViewModel({
    required this.item,
    this.showCustomerBudgets = true,
    ShareLinkRepository? shareLinkRepository,
    UserRepository? userRepository,
    CheckAiAccessUsecase? checkAiAccess,
  }) : _shareLinkRepository =
           shareLinkRepository ?? getIt<ShareLinkRepository>(),
       _userRepository = userRepository ?? getIt<UserRepository>(),
       _checkAiAccess = checkAiAccess ?? getIt<CheckAiAccessUsecase>() {
    shareCommand = Command0(_executeShare);
  }

  /// Assinante vai direto ao compartilhamento; os demais veem o anúncio.
  bool get isSubscriber =>
      _userRepository.selectUser.value?.autoRenewing ?? false;

  /// Opções agrupadas por seção (seções vazias não aparecem).
  Map<BudgetOptionSection, List<BudgetOption>> get sections {
    final all = <BudgetOption>[
      if (showCustomerBudgets)
        BudgetOption(
          type: BudgetOptionType.customerBudgets,
          section: BudgetOptionSection.budget,
          icon: Icons.folder_shared_outlined,
          color: primaryColor,
          title: BudgetStrings.customerBudgetsTitle,
          subtitle: BudgetStrings.optionCustomerBudgetsDesc,
        ),
      BudgetOption(
        type: BudgetOptionType.metrics,
        section: BudgetOptionSection.budget,
        icon: Icons.insights_outlined,
        color: statusApprovedColor,
        title: BudgetStrings.optionMetrics,
        subtitle: BudgetStrings.optionMetricsDesc,
      ),
      BudgetOption(
        type: BudgetOptionType.comments,
        section: BudgetOptionSection.budget,
        icon: Icons.comment_outlined,
        color: statusPendingColor,
        title: BudgetStrings.optionComments,
        subtitle: BudgetStrings.optionCommentsDesc,
      ),
      BudgetOption(
        type: BudgetOptionType.shareLink,
        section: BudgetOptionSection.share,
        icon: Icons.share_outlined,
        color: buttonColor,
        title: BudgetStrings.optionShareLink,
        subtitle: BudgetStrings.optionShareLinkDesc,
      ),
      BudgetOption(
        type: BudgetOptionType.pdfExecutive,
        section: BudgetOptionSection.share,
        icon: Icons.business_center_outlined,
        color: priceTextColor,
        title: BudgetStrings.optionPdfExecutive,
        subtitle: BudgetStrings.optionPdfExecutiveDesc,
      ),
      BudgetOption(
        type: BudgetOptionType.pdfProfessional,
        section: BudgetOptionSection.share,
        icon: Icons.workspace_premium_outlined,
        color: budgetOptionOrangeColor,
        title: BudgetStrings.optionPdfProfessional,
        subtitle: BudgetStrings.optionPdfProfessionalDesc,
      ),
      BudgetOption(
        type: BudgetOptionType.receipt,
        section: BudgetOptionSection.finance,
        icon: Icons.payments_outlined,
        color: cartAccentColor,
        title: BudgetStrings.optionReceipt,
        subtitle: BudgetStrings.optionReceiptDesc,
      ),
      // Comprovantes: só assinantes (mesmo gate do chat com IA).
      if (_checkAiAccess())
        BudgetOption(
          type: BudgetOptionType.proofs,
          section: BudgetOptionSection.finance,
          icon: Icons.attach_file_rounded,
          color: budgetOptionPinkColor,
          title: PaymentProofStrings.menuLabel,
          subtitle: BudgetStrings.optionProofsDesc,
        ),
    ];
    return {
      for (final section in BudgetOptionSection.values)
        if (all.any((o) => o.section == section))
          section: all.where((o) => o.section == section).toList(),
    };
  }

  /// Gera o link público Web do orçamento (número do endereço + token
  /// provisório do Firebase) e abre a sheet nativa de compartilhamento.
  ///
  /// O `id` do orçamento (`CustomerInfo.id`) é o "número do endereço" usado
  /// para localizá-lo no fluxo Web — nunca o telefone.
  Future<Result<void>> _executeShare() async {
    final enderecoNumero = item.id;
    if (enderecoNumero == null || enderecoNumero.isEmpty) {
      return Result.error(
        BudgetShareException(
          BudgetStrings.shareNotYetTitle,
          BudgetStrings.shareSaveBefore,
          isWarning: true,
        ),
      );
    }
    try {
      final url = await _shareLinkRepository.buildShareUrl(
        enderecoNumero: enderecoNumero,
      );
      if (url == null) {
        return Result.error(
          BudgetShareException(
            BudgetStrings.shareErrorTitle,
            BudgetStrings.shareErrorGenerateLink,
          ),
        );
      }
      await SharePlus.instance.share(
        ShareParams(text: url, subject: BudgetStrings.shareSubject),
      );
      return const Result.ok(null);
    } catch (_) {
      return Result.error(
        BudgetShareException(
          BudgetStrings.shareErrorTitle,
          BudgetStrings.shareErrorShareLink,
        ),
      );
    }
  }

  @override
  void dispose() {
    shareCommand.dispose();
    super.dispose();
  }
}
