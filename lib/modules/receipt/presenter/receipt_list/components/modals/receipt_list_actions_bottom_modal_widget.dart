import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';
import 'package:oflite/shared/common/widgets/label/expansion_card_label.dart';

/// Bottom modal com os detalhes do recibo e as ações Excluir/Abrir.
/// Cada ação fecha o modal antes de chamar o callback.
class ReceiptListActionsBottomModalWidget extends StatelessWidget {
  const ReceiptListActionsBottomModalWidget({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
    required this.onOpen,
  });

  final Receipt item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onDelete;
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
              item.descricao ?? '',
              style: const TextStyle(
                color: whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${ReceiptPtString.receiptNumber} ${item.id}',
              style: const TextStyle(color: mutedTextColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Divider(color: cardBorderColor, height: 1),
            _label(ReceiptPtString.detailDate, item.data ?? ''),
            _label(
              ReceiptPtString.detailValue,
              moneyConvert.convertFromDouble(item.valorTotal ?? 0),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: ReceiptPtString.deleteLabel,
                    backgroundColor: statusRejectedColor.withValues(
                      alpha: 0.15,
                    ),
                    onPressed: () => _run(context, onDelete),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: ReceiptPtString.openLabel,
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
