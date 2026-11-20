import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Rodapé da lista de recibos (mesmo visual do total dos comprovantes):
/// quantidade à esquerda, soma dos recibos em destaque.
class ReceiptTotalBar extends StatelessWidget {
  const ReceiptTotalBar({super.key, required this.count, required this.total});

  final int count;

  /// Valor já formatado em moeda.
  final String total;

  @override
  Widget build(BuildContext context) {
    final muted = GoogleFonts.heebo(color: mutedTextColor, fontSize: 12);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: secondaryColor,
        border: Border(top: BorderSide(color: sheetHandleColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(ReceiptPtString.receiptsCount(count), style: muted),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ReceiptPtString.receiptsTotalLabel, style: muted),
                Text(
                  total,
                  style: GoogleFonts.heebo(
                    color: buttonColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
