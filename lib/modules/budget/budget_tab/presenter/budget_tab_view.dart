import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/budget/budget_creator/presenter/budget_creator_view.dart';
import 'package:oflite/modules/pdf/pdf_budget/presenter/pdf_budget_view.dart';
import 'package:oflite/modules/pdf/pdf_menu/presenter/pdf_menu_view.dart';
import 'package:oflite/shared/models/customer_info.dart';
import '../../budget_list_items/presenter/budget_list_items_view.dart';
import 'budget_tab_view_model.dart';

class BudgetTabView extends StatefulWidget {
  final CustomerInfo item;
  const BudgetTabView({Key? key, required this.item}) : super(key: key);

  @override
  State<BudgetTabView> createState() => _BudgetTabView();
}

class _BudgetTabView extends State<BudgetTabView> {
  final BudgetTabViewModel _viewModel = BudgetTabViewModel();
  double we = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    we = MediaQuery.of(context).size.width;
    final List children = [
      BudgetCreatorView(item: widget.item),
      BudgetListItemsView(item: widget.item),
      const PdfBudgetView(),
      PdfMenuView(item: widget.item),
    ];
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          body: children[_viewModel.currentIndex],
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: secondaryColor,
            ),
            child: BottomNavigationBar(
              selectedItemColor: Colors.cyan[50],
              showUnselectedLabels: true,
              selectedLabelStyle:
                  const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
              unselectedItemColor: Colors.grey,
              onTap: (index) =>
                  _viewModel.onTabTapped(index, context, we, widget.item),
              currentIndex: _viewModel.currentIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Cliente',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Itens',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.picture_as_pdf),
                  label: 'PDF',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: 'Mais',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
