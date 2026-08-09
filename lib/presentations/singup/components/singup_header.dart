import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

/// Cabeçalho da tela de cadastro: botão voltar + título + subtítulo.
///
/// Component `Stateless` puro — recebe apenas callbacks. Não acessa services
/// nem o ViewModel.
class SingUpHeader extends StatelessWidget {
  final VoidCallback onBack;

  const SingUpHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: he * 0.05),
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
        SizedBox(height: he * 0.03),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            margin: const EdgeInsets.only(right: 80.0),
            child: Text(
              "Criar uma conta",
              style: GoogleFonts.heebo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 35,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            margin: const EdgeInsets.only(right: 130.0),
            child: Text(
              "Insira suas informações abaixo",
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
