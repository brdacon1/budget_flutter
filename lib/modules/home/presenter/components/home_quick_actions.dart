import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/home/presenter/components/home_quick_action_item.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';

/// Atalhos da Home em grade de 3 colunas (todos visíveis, sem rolagem).
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
    required this.onCreateReceipt,
    required this.onSaveProofs,
  });

  final IconData createBudgetIcon;
  final IconData budgetListIcon;
  final IconData reportsIcon;
  final IconData registerItemsIcon;
  final VoidCallback onCreateBudget;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenReports;
  final VoidCallback onRegisterItems;
  final VoidCallback onCreateReceipt;
  final VoidCallback onSaveProofs;

  @override
  Widget build(BuildContext context) {
    final items = [
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
        icon: Icons.receipt_long_outlined,
        label: HomeStrings.createReceipts,
        onTap: onCreateReceipt,
      ),
      HomeQuickActionItem(
        icon: Icons.upload_file_outlined,
        label: HomeStrings.saveProofs,
        onTap: onSaveProofs,
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
    ];
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 3) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = i; j < i + 3; j++) ...[
                if (j > i) const SizedBox(width: 12),
                Expanded(
                  child: j < items.length ? items[j] : const SizedBox(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
