import 'package:flutter/material.dart';
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
    var he = MediaQuery.of(context).size.height;
    var we = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: he * 0.07),
        GestureDetector(
          onTap: onBack,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.04),
            child: const Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ),
        SizedBox(height: he * 0.02),
        Container(
          alignment: Alignment.topLeft,
          margin: EdgeInsets.only(left: we * 0.048),
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
          margin: EdgeInsets.only(left: we * 0.05),
          child: Text(
            PaymentStrings.paymentDataTitle,
            style: GoogleFonts.heebo(color: Colors.grey, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}
