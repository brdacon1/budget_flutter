import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barra exibida logo acima do teclado enquanto ele está aberto (§17.8).
///
/// Dá ao usuário um jeito explícito de fechar o teclado quando desiste de
/// editar o campo. Substitui o [AppFormSaveButton] enquanto o teclado está
/// visível.
class AppKeyboardDismissBar extends StatelessWidget {
  const AppKeyboardDismissBar({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: secondaryColor,
        border: Border(top: BorderSide(color: cardBorderColor)),
      ),
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
        icon: const Icon(Icons.keyboard_hide_outlined, color: buttonColor),
        label: Text(
          label,
          style: GoogleFonts.heebo(
            color: buttonColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
