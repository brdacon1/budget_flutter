import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/home/presenter/components/home_quick_action_item.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';

/// Atalhos da Home em grade de 4 colunas (todos visíveis, sem rolagem).
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.createBudgetIcon,
    required this.budgetListIcon,
    required this.reportsIcon,
    required this.registerItemsIcon,
    required this.onCreateBudget,
    this.onShareBudgets,
    required this.onOpenBudgets,
    required this.onOpenReports,
    required this.onRegisterItems,
    required this.onCreateReceipt,
    required this.onOpenReceipts,
    required this.onSaveProofs,
    required this.onConfigurePdf,
    required this.onPdfType,
    required this.onClientBudgets,
    required this.onSaveComments,
  });

  final IconData createBudgetIcon;
  final IconData budgetListIcon;
  final IconData reportsIcon;
  final IconData registerItemsIcon;
  final VoidCallback onCreateBudget;

  /// `null` = sem orçamentos: o atalho não aparece.
  final VoidCallback? onShareBudgets;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenReports;
  final VoidCallback onRegisterItems;
  final VoidCallback onCreateReceipt;
  final VoidCallback onOpenReceipts;
  final VoidCallback onSaveProofs;
  final VoidCallback onConfigurePdf;
  final VoidCallback onPdfType;
  final VoidCallback onClientBudgets;
  final VoidCallback onSaveComments;

  @override
  Widget build(BuildContext context) {
    final items = [
      HomeQuickActionItem(
        icon: createBudgetIcon,
        label: HomeStrings.createBudgets,
        onTap: onCreateBudget,
      ),
      if (onShareBudgets != null)
        HomeQuickActionItem(
          icon: Icons.share_outlined,
          label: HomeStrings.shareBudgets,
          onTap: onShareBudgets!,
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
        icon: Icons.fact_check_outlined,
        label: HomeStrings.receiptList,
        onTap: onOpenReceipts,
      ),
      HomeQuickActionItem(
        icon: Icons.upload_file_outlined,
        label: HomeStrings.saveProofs,
        onTap: onSaveProofs,
      ),
      HomeQuickActionItem(
        icon: Icons.person_search_outlined,
        label: HomeStrings.clientBudgets,
        onTap: onClientBudgets,
      ),
      HomeQuickActionItem(
        icon: Icons.picture_as_pdf_outlined,
        label: HomeStrings.configurePdf,
        onTap: onConfigurePdf,
      ),
      HomeQuickActionItem(
        icon: Icons.style_outlined,
        label: HomeStrings.pdfType,
        onTap: onPdfType,
      ),
      HomeQuickActionItem(
        icon: Icons.chat_bubble_outline,
        label: HomeStrings.saveComments,
        onTap: onSaveComments,
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
        for (var i = 0; i < items.length; i += 4) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = i; j < i + 4; j++) ...[
                if (j > i) const SizedBox(width: 8),
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
