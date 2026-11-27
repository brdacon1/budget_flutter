import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/home/presenter/components/home_analysis_card.dart';
import 'package:oflite/modules/home/presenter/components/home_chat_fab.dart';
import 'package:oflite/modules/home/presenter/components/home_header.dart';
import 'package:oflite/modules/home/presenter/components/home_hero_card.dart';
import 'package:oflite/modules/home/presenter/components/home_overview.dart';
import 'package:oflite/modules/home/presenter/components/home_tablet_layout.dart';
import 'package:oflite/modules/home/presenter/components/home_quick_actions.dart';
import 'package:oflite/modules/home/presenter/home_view_model.dart';
import 'package:oflite/modules/product/presenter/product_price_list/product_price_list_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_page_container.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';

import 'strings/home_pt_string.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.companyLogo,
    this.companyName = '',
    this.onEditLogo,
    this.chatIcon = Icons.support_agent,
    this.budgetsIcon = Icons.inventory_outlined,
    this.reportsIcon = Icons.dashboard,
    this.onOpenChat,
    this.onCreateBudget,
    this.onOpenBudgets,
    this.onOpenReports,
    this.onCreateReceipt,
    this.onSaveProofs,
  });

  final Uint8List? companyLogo;
  final String companyName;
  final VoidCallback? onEditLogo;
  final IconData chatIcon;
  final IconData budgetsIcon;
  final IconData reportsIcon;
  final VoidCallback? onOpenChat;
  final VoidCallback? onCreateBudget;
  final VoidCallback? onOpenBudgets;
  final VoidCallback? onOpenReports;
  final VoidCallback? onCreateReceipt;
  final VoidCallback? onSaveProofs;

  @override
  State<HomeView> createState() => _HomeView();
}

class _HomeView extends State<HomeView> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<HomeViewModel>();
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

  Future<void> _openItems() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductPriceListView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    final twoColumns = ResponsiveWidget.isDesktop(context);
    const gap = SizedBox(height: defaultPadding, width: defaultPadding);
    void noop() {}
    final onCreate = widget.onCreateBudget ?? noop;

    final top = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeader(
          companyLogo: widget.companyLogo,
          companyName: widget.companyName,
          onEditLogo: widget.onEditLogo ?? noop,
        ),
        gap,
        HomeHeroCard(summary: vm.summary, month: vm.month),
        gap,
        HomeQuickActions(
          createBudgetIcon: widget.chatIcon,
          budgetListIcon: widget.budgetsIcon,
          reportsIcon: widget.reportsIcon,
          registerItemsIcon: Icons.sell_outlined,
          onCreateBudget: onCreate,
          onOpenBudgets: widget.onOpenBudgets ?? noop,
          onOpenReports: widget.onOpenReports ?? noop,
          onCreateReceipt: widget.onCreateReceipt ?? noop,
          onSaveProofs: widget.onSaveProofs ?? noop,
          onRegisterItems: _openItems,
        ),
      ],
    );

    final overview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeOverview(
          summary: vm.summary,
          month: vm.month,
          canGoNext: vm.canGoNext,
          onPrevious: vm.previousMonth,
          onNext: vm.nextMonth,
        ),
        SizedBox(
          height: 2,
          child:
              vm.loadCommand.running ? const LinearProgressIndicator() : null,
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
        gap,
        HomeAnalysisCard(items: vm.comparison),
      ],
    );

    return Scaffold(
      floatingActionButton: HomeChatFab(
        icon: widget.chatIcon,
        onTap: widget.onOpenChat ?? noop,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.loadCommand.execute(true),
          child: AppPageContainer(
            width: AppPageWidth.wide,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                defaultPadding,
                defaultPadding,
                defaultPadding,
                112,
              ),
              children:
                  twoColumns
                      ? [
                        HomeTabletLayout(
                          viewModel: vm,
                          companyLogo: widget.companyLogo,
                          companyName: widget.companyName,
                          onEditLogo: widget.onEditLogo ?? noop,
                          chatIcon: widget.chatIcon,
                          budgetsIcon: widget.budgetsIcon,
                          reportsIcon: widget.reportsIcon,
                          registerItemsIcon: Icons.sell_outlined,
                          onCreateBudget: onCreate,
                          onOpenBudgets: widget.onOpenBudgets ?? noop,
                          onOpenReports: widget.onOpenReports ?? noop,
                          onCreateReceipt: widget.onCreateReceipt ?? noop,
                          onSaveProofs: widget.onSaveProofs ?? noop,
                          onRegisterItems: _openItems,
                        ),
                      ]
                      : [top, gap, overview],
            ),
          ),
        ),
      ),
    );
  }
}
