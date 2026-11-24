import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Rodapé da lista de comprovantes (mesmo visual do total dos itens do
/// orçamento): quantidade à esquerda, soma dos valores em destaque.
class PaymentProofTotalBar extends StatelessWidget {
  const PaymentProofTotalBar({
    super.key,
    required this.count,
    required this.total,
    this.countText,
    this.counterText,
    this.totalLabel,
  });

  final int count;

  /// Textos próprios (ex.: notas fiscais). Padrão: comprovantes.
  final String? countText;
  final String? counterText;
  final String? totalLabel;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(countText ?? PaymentProofStrings.proofsCount(count), style: muted),
                  const SizedBox(height: 2),
                  Text(counterText ?? PaymentProofStrings.listCounter(count), style: muted),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(totalLabel ?? PaymentProofStrings.totalLabel, style: muted),
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
