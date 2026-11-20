import 'package:oflite/modules/receipt/domain/entity/payment_method.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';
import 'package:oflite/shared/common/widgets/label/expansion_card_label.dart';

/// Bottom modal com os detalhes do pagamento e as ações Excluir/Editar.
/// Cada ação fecha o modal antes de chamar o callback.
class ReceiptPaymentListActionsBottomModalWidget extends StatelessWidget {
  const ReceiptPaymentListActionsBottomModalWidget({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
    required this.onEdit,
  });

  final PaymentCustomer item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
              item.description ?? '',
              style: const TextStyle(
                color: whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: cardBorderColor, height: 1),
            _label(
              PaymentStrings.detailMethod,
              PaymentMethod.labelOf(item.method),
            ),
            _label(
              PaymentStrings.detailValue,
              moneyConvert.convertFromDouble(item.price ?? 0),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: PaymentStrings.deleteLabel,
                    backgroundColor: statusRejectedColor.withValues(
                      alpha: 0.15,
                    ),
                    onPressed: () => _run(context, onDelete),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ActionButton(
                    icon: Icons.edit_outlined,
                    label: PaymentStrings.editLabel,
                    backgroundColor: buttonColor.withValues(alpha: 0.25),
                    onPressed: () => _run(context, onEdit),
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
