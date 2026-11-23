import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';
import 'components/dashboard_month_filter.dart';
import 'components/dashboard_receipts_comparison.dart';
import 'components/dashboard_sold_items.dart';
import 'components/dashboard_status_overview.dart';
import 'components/dashboard_monthly_progress.dart';
import 'components/header.dart';
import 'dashboard_view_model.dart';
import 'strings/dashboard_pt_string.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardView();
}

class _DashboardView extends State<DashboardView> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<DashboardViewModel>();
    _viewModel.addListener(_refresh);
    _viewModel.loadCommand.addListener(_refresh);
    _viewModel.loadCommand.execute(false);
  }

  @override
  void dispose() {
    _viewModel.loadCommand.removeListener(_refresh);
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    // Duas colunas só em tela larga; abaixo disso uma coluna (celular e
    // tablet estreito): a coluna do resumo precisa de ~400 px.
    final twoColumns = ResponsiveWidget.isDesktop(context);
    const gap = SizedBox(height: defaultPadding, width: defaultPadding);
    final overview = Column(
      children: [
        DashboardStatusOverview(summary: vm.summary),
        gap,
        DashboardSoldItems(summary: vm.summary),
      ],
    );
    final charts = [
      DashboardMonthlyProgress(summary: vm.summary),
      gap,
      DashboardReceiptsComparison(items: vm.comparison),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.loadCommand.execute(true),
          child: ListView(
            padding: const EdgeInsets.all(defaultPadding),
            children: [
              const Header(),
              gap,
              DashboardMonthFilter(
                month: vm.month,
                canGoNext: vm.canGoNext,
                onPrevious: vm.previousMonth,
                onNext: vm.nextMonth,
              ),
              SizedBox(
                height: 2,
                child:
                    vm.loadCommand.running
                        ? const LinearProgressIndicator()
                        : null,
              ),
              if (vm.loadCommand.error)
                Padding(
                  padding: const EdgeInsets.only(top: defaultPadding),
                  child: Text(
                    DashboardStrings.loadError,
                    style: const TextStyle(color: statusRejectedColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              gap,
              if (!twoColumns) ...[overview, gap, ...charts],
              if (twoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Column(children: charts)),
                    gap,
                    Expanded(flex: 2, child: overview),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
