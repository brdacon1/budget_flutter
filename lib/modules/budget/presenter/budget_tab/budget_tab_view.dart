import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/budget_creator_view.dart';
import 'package:oflite/modules/budget/presenter/budget_list_items/budget_list_items_view.dart';
import 'package:oflite/modules/budget/presenter/budget_options/budget_options_view.dart';
import 'package:oflite/modules/budget/presenter/budget_tab/budget_tab_view_model.dart';
import 'package:oflite/modules/pdf/presenter/pdf_budget/pdf_budget_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_master_detail.dart';

class BudgetTabView extends StatefulWidget {
  final CustomerInfo item;

  /// Aba aberta ao entrar (0 Cliente, 1 Itens, 2 PDF, 3 Mais).
  final int initialIndex;

  /// Aberto por "Orçamentos do cliente": o Mais não repete essa opção
  /// (evita abrir a lista dentro da lista em loop).
  final bool fromCustomerBudgets;

  const BudgetTabView({
    super.key,
    required this.item,
    this.initialIndex = 0,
    this.fromCustomerBudgets = false,
  });

  @override
  State<BudgetTabView> createState() => _BudgetTabView();
}

class _BudgetTabView extends State<BudgetTabView> {
  final BudgetTabViewModel _viewModel = getIt<BudgetTabViewModel>();
  double we = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  static const List<({IconData icon, String label})> _tabs = [
    (icon: Icons.person, label: 'Cliente'),
    (icon: Icons.list, label: 'Itens'),
    (icon: Icons.picture_as_pdf, label: 'PDF'),
    (icon: Icons.more_horiz, label: 'Mais'),
  ];

  /// Bottom navigation do celular (inalterada).
  Widget _buildBottomNavigationBar(BuildContext context, int tabCount) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: secondaryColor),
      child: BottomNavigationBar(
        selectedItemColor: tabSelectedColor,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
        ),
        unselectedItemColor: tabUnselectedColor,
        onTap:
            (index) => _viewModel.onTabTapped(index, context, we, widget.item),
        currentIndex: _viewModel.currentIndex,
        items: [
          for (final tab in _tabs.take(tabCount))
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    we = MediaQuery.of(context).size.width;
    // iPad com 3 painéis: "Mais" fica no painel da direita, não na barra.
    final tabCount = AppAsidePane.activeOf(context) ? 3 : _tabs.length;
    if (_viewModel.currentIndex >= tabCount) _viewModel.currentIndex = 0;
    final List children = [
      BudgetCreatorView(item: widget.item),
      BudgetListItemsView(item: widget.item),
      const PdfBudgetView(isTabRoot: true),
      BudgetOptionsView(
        item: widget.item,
        showCustomerBudgets: !widget.fromCustomerBudgets,
      ),
    ];
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          body: children[_viewModel.currentIndex],
          bottomNavigationBar: _buildBottomNavigationBar(context, tabCount),
        );
      },
    );
  }
}
