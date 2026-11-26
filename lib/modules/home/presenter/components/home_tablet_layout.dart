import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_monthly_progress.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_sold_items.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_status_overview.dart';
import 'package:oflite/modules/home/presenter/components/home_analysis_card.dart';
import 'package:oflite/modules/home/presenter/components/home_greeting.dart';
import 'package:oflite/modules/home/presenter/components/home_header.dart';
import 'package:oflite/modules/home/presenter/components/home_hero_card.dart';
import 'package:oflite/modules/home/presenter/components/home_overview.dart';
import 'package:oflite/modules/home/presenter/components/home_quick_action_tile.dart';
import 'package:oflite/modules/home/presenter/home_view_model.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Composição da Home em tela larga (`expanded`): painel em blocos — topo com
/// saudação/hero/atalhos grandes + visão geral, depois gráficos do mês.
/// O layout do celular não usa este widget.
class HomeTabletLayout extends StatelessWidget {
  const HomeTabletLayout({
    super.key,
    required this.viewModel,
    required this.companyLogo,
    required this.companyName,
    required this.onEditLogo,
    required this.chatIcon,
    required this.budgetsIcon,
    required this.reportsIcon,
    required this.registerItemsIcon,
    required this.onCreateBudget,
    required this.onOpenBudgets,
    required this.onOpenReports,
    required this.onRegisterItems,
  });

  final HomeViewModel viewModel;
  final Uint8List? companyLogo;
  final String companyName;
  final VoidCallback onEditLogo;
  final IconData chatIcon;
  final IconData budgetsIcon;
  final IconData reportsIcon;
  final IconData registerItemsIcon;
  final VoidCallback onCreateBudget;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenReports;
  final VoidCallback onRegisterItems;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    const gap = SizedBox(height: defaultPadding, width: defaultPadding);

    Widget pair(Widget left, Widget right) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: left),
          gap,
          Expanded(flex: 3, child: right),
        ],
      ),
    );

    final tiles = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: HomeQuickActionTile(
            icon: chatIcon,
            label: HomeStrings.createBudgets,
            onTap: onCreateBudget,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeQuickActionTile(
            icon: budgetsIcon,
            label: HomeStrings.budgetList,
            onTap: onOpenBudgets,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeQuickActionTile(
            icon: reportsIcon,
            label: HomeStrings.reports,
            onTap: onOpenReports,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeQuickActionTile(
            icon: registerItemsIcon,
            label: HomeStrings.registerItems,
            onTap: onRegisterItems,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeader(
          companyLogo: companyLogo,
          companyName: companyName,
          onEditLogo: onEditLogo,
        ),
        gap,
        HomeGreeting(firstName: vm.firstName, singleLine: true),
        gap,
        // Topo: hero + atalhos à esquerda e visão geral à direita, com a
        // mesma altura (base alinhada).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHeroCard(summary: vm.summary, month: vm.month),
                    gap,
                    Expanded(child: tiles),
                  ],
                ),
              ),
              gap,
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: HomeOverview(
                        fill: true,
                        summary: vm.summary,
                        month: vm.month,
                        canGoNext: vm.canGoNext,
                        onPrevious: vm.previousMonth,
                        onNext: vm.nextMonth,
                      ),
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
                          HomeStrings.loadError,
                          style: const TextStyle(color: statusRejectedColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap,
        pair(
          DashboardStatusOverview(summary: vm.summary),
          HomeAnalysisCard(items: vm.comparison, fill: true),
        ),
        gap,
        pair(
          DashboardSoldItems(summary: vm.summary),
          DashboardMonthlyProgress(summary: vm.summary),
        ),
      ],
    );
  }
}
