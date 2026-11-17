import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/card/budget_list_status_chip.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';
import 'package:oflite/shared/common/widgets/label/expansion_card_label.dart';

/// Bottom modal com os detalhes do orçamento e as ações Excluir/Duplicar/Abrir.
/// Cada ação fecha o modal antes de chamar o callback.
class BudgetListActionsBottomModalWidget extends StatelessWidget {
  const BudgetListActionsBottomModalWidget({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
    required this.onDuplicate,
    required this.onOpen,
  });

  final CustomerInfo item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onOpen;

  void _run(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Widget _label(String name, String value) {
    return ExpansionCardLabel(
      nameText: name,
      textData: value,
      horizontalPadding: 0,
      verticalPadding: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = item.checkBox ?? false;

    return Container(
      decoration: const BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: sheetHandleColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              item.customerName ?? '',
              style: const TextStyle(
                color: whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${BudgetStrings.budgetNumber} ${item.id}',
              style: const TextStyle(color: mutedTextColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Divider(color: cardBorderColor, height: 1),
            _label(BudgetStrings.detailDate, item.data ?? ''),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    BudgetStrings.detailStatus,
                    style: const TextStyle(color: whiteColor, fontSize: 12),
                  ),
                  BudgetListStatusChip(status: item.status),
                ],
              ),
            ),
            _label(BudgetStrings.detailPhone, item.phone ?? ''),
            _label(
              BudgetStrings.detailValue,
              moneyConvert.convertFromDouble(item.totalValue ?? 0),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon:
                        selected
                            ? Icons.check_circle_outline
                            : Icons.delete_outline_rounded,
                    label:
                        selected
                            ? BudgetStrings.actionSelected
                            : BudgetStrings.actionDelete,
                    backgroundColor: statusRejectedColor.withValues(
                      alpha: 0.15,
                    ),
                    onPressed: () => _run(context, onDelete),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ActionButton(
                    icon: Icons.copy_rounded,
                    label: BudgetStrings.actionDuplicate,
                    onPressed: () => _run(context, onDuplicate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: BudgetStrings.actionOpen,
                    backgroundColor: buttonColor.withValues(alpha: 0.25),
                    onPressed: () => _run(context, onOpen),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
