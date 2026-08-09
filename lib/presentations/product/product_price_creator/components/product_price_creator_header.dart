import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/common/strings/product_strings.dart';

/// Cabeçalho da tela de criação/edição de produto ou serviço.
///
/// Botão de voltar + título dinâmico (Criar/Editar item) + subtítulo fixo.
/// `StatelessWidget` puro — recebe o título e o callback de voltar, sem
/// conhecer o ViewModel.
class ProductPriceCreatorHeader extends StatelessWidget {
  const ProductPriceCreatorHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;

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
              title,
              style: GoogleFonts.heebo(
                color: whiteColor,
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
              ProductStrings.subtitle,
              style: GoogleFonts.heebo(
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        SizedBox(height: he * 0.02),
      ],
    );
  }
}
