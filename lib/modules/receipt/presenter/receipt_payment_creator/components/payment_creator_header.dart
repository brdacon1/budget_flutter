import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';

class PaymentCreatorHeader extends StatelessWidget {
  final String? titlePage;
  final VoidCallback onBack;

  const PaymentCreatorHeader({
    super.key,
    required this.titlePage,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: MediaQuery.paddingOf(context).top + 16),
        GestureDetector(
          onTap: onBack,
          child: Container(
            alignment: Alignment.topLeft,
            margin: const EdgeInsets.only(left: 16),
            child: const Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.only(left: 20),
          child: Text(
            titlePage!,
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.only(left: 20),
          child: Text(
            PaymentStrings.paymentDataTitle,
            style: GoogleFonts.heebo(color: Colors.grey, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}
