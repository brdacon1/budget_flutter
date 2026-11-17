import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class PaymentTotalBar extends StatelessWidget {
  final double totalPaid;
  final int count;
  final ConvertCoinRepository moneyConvert;

  const PaymentTotalBar({
    super.key,
    required this.totalPaid,
    required this.count,
    required this.moneyConvert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: secondaryColor,
        border: Border(top: BorderSide(color: cardBorderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              PaymentStrings.paymentsCount(count),
              style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 13),
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  PaymentStrings.totalPaidLabel,
                  style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 13),
                ),
                Text(
                  moneyConvert.convertFromDouble(totalPaid),
                  style: GoogleFonts.heebo(
                    color: buttonColor,
                    fontSize: 22,
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
