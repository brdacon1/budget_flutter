import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header da tela de lista de recibos (voltar + título "Recibos").
///
/// Component `Stateless` puro — recebe o callback de voltar. Não acessa
/// services nem o ViewModel. Espelha o layout original da View.
class AppHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String titleText;

  const AppHeader({super.key, required this.onBack, required this.titleText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: MediaQuery.paddingOf(context).top + 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
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
          ],
        ),
        const SizedBox(height: 24),
        Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.only(left: 16),
          child: Text(
            titleText,
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
