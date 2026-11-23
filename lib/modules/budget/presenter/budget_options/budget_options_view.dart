import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_list/budget_comment_list_view.dart';
import 'package:oflite/modules/budget/presenter/budget_list/budget_list_view.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/budget_metrics_view.dart';
import 'package:oflite/modules/budget/presenter/budget_options/budget_options_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_options/components/budget_options_section.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_list/payment_proof_list_view.dart';
import 'package:oflite/modules/pdf/domain/entity/pdf_layout_type.dart';
import 'package:oflite/modules/pdf/presenter/pdf_budget/pdf_budget_view.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/receipt_list_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class BudgetOptionsView extends StatefulWidget {
  final CustomerInfo item;

  /// `false` quando aberto por "Orçamentos do cliente": evita repetir a
  /// opção (abrir a lista dentro da lista em loop).
  final bool showCustomerBudgets;

  const BudgetOptionsView({
    super.key,
    required this.item,
    this.showCustomerBudgets = true,
  });

  @override
  State<BudgetOptionsView> createState() => _BudgetOptionsViewState();
}

class _BudgetOptionsViewState extends State<BudgetOptionsView> {
  late final BudgetOptionsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetOptionsViewModel(
      item: widget.item,
      showCustomerBudgets: widget.showCustomerBudgets,
    );
    _viewModel.shareCommand.addListener(_onShareChanged);
  }

  @override
  void dispose() {
    _viewModel.shareCommand.removeListener(_onShareChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onShareChanged() {
    final cmd = _viewModel.shareCommand;
    if (!cmd.error) return;
    final failure = (cmd.result as Error<void>).error;
    if (failure is! BudgetShareException) return;
    final alert = getIt<DisplayAlertRepository>();
    failure.isWarning
        ? alert.notificationWarning(context, failure.title, failure.message)
        : alert.notificationError(context, failure.title, failure.message);
  }

  String _sectionTitle(BudgetOptionSection section) {
    switch (section) {
      case BudgetOptionSection.budget:
        return BudgetStrings.optionsSectionBudget;
      case BudgetOptionSection.share:
        return BudgetStrings.optionsSectionShare;
      case BudgetOptionSection.finance:
        return BudgetStrings.optionsSectionFinance;
    }
  }

  Future<void> _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _share() async {
    var watchedAd = false;
    if (!_viewModel.isSubscriber) {
      final choice = await getIt<DisplayAlertRepository>().adsNotification(
        context,
      );
      if (!mounted) return;
      if (choice == BudgetStrings.goPremium) {
        await _push(SubscriptionView());
        return;
      }
      if (choice != BudgetStrings.watchAd) return;
      watchedAd = true;
    }
    await _viewModel.shareCommand.execute();
    if (watchedAd) getIt<AdsRepository>().showInterstitial();
  }

  Future<void> _open(BudgetOption option) async {
    switch (option.type) {
      case BudgetOptionType.customerBudgets:
        await _push(BudgetListView(customer: widget.item));
      case BudgetOptionType.metrics:
        await _push(BudgetMetricsView(item: widget.item));
      case BudgetOptionType.comments:
        await _push(BudgetCommentListView(item: widget.item));
      case BudgetOptionType.receipt:
        await _push(ReceiptListView(item: widget.item));
      case BudgetOptionType.proofs:
        await _push(PaymentProofListView(item: widget.item));
      case BudgetOptionType.pdfExecutive:
        await _push(const PdfBudgetView(layoutType: PdfLayoutType.executive));
      case BudgetOptionType.pdfProfessional:
        await _push(
          const PdfBudgetView(layoutType: PdfLayoutType.professional),
        );
      case BudgetOptionType.shareLink:
        await _share();
    }
    // Reavalia o gate de assinante (ex.: voltou da assinatura).
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: <Widget>[
          AppHeaderSecondTitle(
            titlePage: BudgetStrings.optionsTitle,
            secondTitle: BudgetStrings.optionsSubtitle,
            onBack: () => Navigator.pop(context, true),
            isBottomPadding: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final entry in _viewModel.sections.entries)
                  BudgetOptionsSection(
                    title: _sectionTitle(entry.key),
                    options: entry.value,
                    onOptionTap: _open,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
