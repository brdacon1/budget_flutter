import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/strings/receipt_strings.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';

/// Header da tela de criação/edição de recibo (voltar + título + subtítulo).
///
/// Component `Stateless` puro — recebe o título e o callback de voltar. Não
/// acessa services nem o ViewModel. Espelha o layout original da View
/// (espaçamentos em `%` da tela), apenas extraído para `components/`.
class ReceiptCreatorHeader extends StatelessWidget {
  final String titlePage;
  final VoidCallback onBack;

  const ReceiptCreatorHeader({
    super.key,
    required this.titlePage,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final double we = MediaQuery.of(context).size.width;
    final double he = MediaQuery.of(context).size.height;
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
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.048),
            child: Text(
              titlePage,
              style: GoogleFonts.heebo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.05),
            child: Text(
              ReceiptStrings.subtitle,
              style: GoogleFonts.heebo(
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
