import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/budget_metrics_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_hero_card.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_methods_card.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_proof_coverage_card.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_tile.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';

/// Tela **Métricas** do orçamento (acessada pelo menu Mais).
class BudgetMetricsView extends StatefulWidget {
  const BudgetMetricsView({
    super.key,
    required this.item,
    this.showBack = true,
  });

  final CustomerInfo item;

  /// `false` no painel de métricas do iPad (não há para onde voltar).
  final bool showBack;

  @override
  State<BudgetMetricsView> createState() => _BudgetMetricsViewState();
}

class _BudgetMetricsViewState extends State<BudgetMetricsView> {
  late final BudgetMetricsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = BudgetMetricsViewModel(item: widget.item);
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.load());
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _vm,
        builder:
            (context, _) => Column(
              children: [
                AppHeaderSecondTitle(
                  titlePage: BudgetStrings.metricsTitle,
                  secondTitle: BudgetStrings.metricsSubtitle(
                    widget.item.id ?? '',
                  ),
                  showBack: widget.showBack,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(child: _body()),
              ],
            ),
      ),
    );
  }

  Widget _body() {
    final m = _vm.metrics;
    if (_vm.loading && m == null) {
      return const Center(
        child: CircularProgressIndicator(color: loadingIndicatorColor),
      );
    }
    if (m == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Text(
          BudgetStrings.metricsLoadError,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: emptyTextColor),
        ),
      );
    }
    return RefreshIndicator(
      color: refreshIndicatorColor,
      backgroundColor: bgColor,
      onRefresh: _vm.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          _pair(
            BudgetMetricsTile(
              icon: Icons.inventory_2_outlined,
              title: BudgetStrings.metricsProducts,
              value: _vm.money(m.productsTotal),
              count: m.productsCount,
            ),
            BudgetMetricsTile(
              icon: Icons.handyman_outlined,
              title: BudgetStrings.metricsServices,
              value: _vm.money(m.servicesTotal),
              count: m.servicesCount,
            ),
          ),
          const SizedBox(height: 12),
          BudgetMetricsHeroCard(
            total: _vm.money(m.budgetTotal),
            toReceive: _vm.money(m.toReceive),
            ratio: m.receivedRatio,
          ),
          const SizedBox(height: 12),
          _pair(
            BudgetMetricsTile(
              icon: Icons.receipt_long_outlined,
              title: BudgetStrings.metricsReceipts,
              value: _vm.money(m.receiptsTotal),
              count: m.receiptsCount,
            ),
            BudgetMetricsTile(
              icon: Icons.attach_file_rounded,
              title: BudgetStrings.metricsProofs,
              value: _vm.money(m.proofsTotal),
              count: m.proofsCount,
            ),
          ),
          const SizedBox(height: 12),
          BudgetMetricsMethodsCard(metrics: m, money: _vm.money),
          const SizedBox(height: 12),
          BudgetMetricsProofCoverageCard(
            ratio: m.provenRatio,
            unproven: _vm.money(m.unprovenTotal),
            hasUnproven: m.unprovenTotal > 0,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: BudgetMetricsTile(
              icon: Icons.list_alt_rounded,
              title: BudgetStrings.metricsItems,
              value: '${m.itemsCount}',
            ),
          ),
        ],
      ),
    );
  }

  /// Dois cards lado a lado com a mesma altura.
  Widget _pair(Widget left, Widget right) => SizedBox(
    height: 108,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    ),
  );
}
