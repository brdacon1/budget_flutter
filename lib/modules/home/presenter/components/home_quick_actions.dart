import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/home/presenter/components/home_quick_action_item.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';

/// Atalhos com os ícones das tabs; rola na horizontal (o 4º aparece ao arrastar).
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.createBudgetIcon,
    required this.budgetListIcon,
    required this.reportsIcon,
    required this.registerItemsIcon,
    required this.onCreateBudget,
    required this.onOpenBudgets,
    required this.onOpenReports,
    required this.onRegisterItems,
  });

  final IconData createBudgetIcon;
  final IconData budgetListIcon;
  final IconData reportsIcon;
  final IconData registerItemsIcon;
  final VoidCallback onCreateBudget;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenReports;
  final VoidCallback onRegisterItems;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          HomeQuickActionItem(
            icon: createBudgetIcon,
            label: HomeStrings.createBudgets,
            onTap: onCreateBudget,
          ),
          HomeQuickActionItem(
            icon: budgetListIcon,
            label: HomeStrings.budgetList,
            onTap: onOpenBudgets,
          ),
          HomeQuickActionItem(
            icon: reportsIcon,
            label: HomeStrings.reports,
            onTap: onOpenReports,
          ),
          HomeQuickActionItem(
            icon: registerItemsIcon,
            label: HomeStrings.registerItems,
            onTap: onRegisterItems,
          ),
        ],
      ),
    );
  }
}
