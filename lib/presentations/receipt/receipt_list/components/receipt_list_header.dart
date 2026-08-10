import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/strings/receipt_strings.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

/// Header da tela de lista de recibos (voltar + título "Recibos").
///
/// Component `Stateless` puro — recebe o callback de voltar. Não acessa
/// services nem o ViewModel. Espelha o layout original da View.
class ReceiptListHeader extends StatelessWidget {
  final VoidCallback onBack;

  const ReceiptListHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final double we = MediaQuery.of(context).size.width;
    final double he = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: he * 0.07),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            GestureDetector(
              onTap: onBack,
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.02),
                child: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: he * 0.03),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.028),
            child: Text(
              ReceiptStrings.listTitle,
              style: GoogleFonts.heebo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        SizedBox(height: he * 0.03),
      ],
    );
  }
}
