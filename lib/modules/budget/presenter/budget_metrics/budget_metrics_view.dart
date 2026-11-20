import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/budget_metrics_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_hero_card.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_methods_card.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_tile.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';

/// Tela **Métricas** do orçamento (acessada pelo menu Mais).
class BudgetMetricsView extends StatefulWidget {
  const BudgetMetricsView({super.key, required this.item});

  final CustomerInfo item;

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
          BudgetMetricsHeroCard(
            total: _vm.money(m.budgetTotal),
            toReceive: _vm.money(m.toReceive),
            ratio: m.receivedRatio,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              BudgetMetricsTile(
                icon: Icons.list_alt_rounded,
                title: BudgetStrings.metricsItems,
                value: '${m.itemsCount}',
              ),
              BudgetMetricsTile(
                icon: Icons.handyman_outlined,
                title: BudgetStrings.metricsServices,
                value: _vm.money(m.servicesTotal),
              ),
              BudgetMetricsTile(
                icon: Icons.receipt_long_outlined,
                title: BudgetStrings.metricsReceipts,
                value: '${m.receiptsCount}',
              ),
              BudgetMetricsTile(
                icon: Icons.attach_file_rounded,
                title: BudgetStrings.metricsProofs,
                value: '${m.proofsCount}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          BudgetMetricsMethodsCard(metrics: m, money: _vm.money),
        ],
      ),
    );
  }
}
