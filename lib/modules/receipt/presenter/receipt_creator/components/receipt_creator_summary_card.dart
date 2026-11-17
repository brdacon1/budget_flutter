import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Identificação imutável do recibo no modo editar (§17.5): nº, data e
/// valor total como texto — nunca como campo desabilitado.
class ReceiptCreatorSummaryCard extends StatelessWidget {
  const ReceiptCreatorSummaryCard({
    super.key,
    required this.id,
    required this.date,
    required this.total,
  });

  final String id;
  final String date;
  final double total;

  @override
  Widget build(BuildContext context) {
    final totalText =
        NumberFormat.simpleCurrency(locale: 'pt_BR').format(total);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sheetHandleColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ReceiptPtString.summaryLabel,
                    style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 12)),
                const SizedBox(height: 2),
                Text('#$id',
                    style: GoogleFonts.heebo(
                        color: whiteColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: mutedTextColor, size: 13),
                  const SizedBox(width: 4),
                  Text(ReceiptPtString.createdOn(date),
                      style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 12)),
                ]),
              ],
            ),
          ),
          Text(totalText,
              style: GoogleFonts.heebo(
                  color: whiteColor, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
