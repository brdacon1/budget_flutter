import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barra exibida logo acima do teclado enquanto ele está aberto (§17.8).
///
/// Dá ao usuário um jeito explícito de fechar o teclado quando desiste de
/// editar o campo. Substitui o [AppFormSaveButton] enquanto o teclado está
/// visível.
///
/// Se esconde sozinha quando o teclado fecha: escuta `didChangeMetrics` e lê
/// o inset real do [View] — não depende de a tela pai reconstruir.
class AppKeyboardDismissBar extends StatefulWidget {
  const AppKeyboardDismissBar({super.key, required this.label});

  final String label;

  @override
  State<AppKeyboardDismissBar> createState() => _AppKeyboardDismissBarState();
}

class _AppKeyboardDismissBarState extends State<AppKeyboardDismissBar>
    with WidgetsBindingObserver {
  bool _keyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keyboardOpen = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final open = View.of(context).viewInsets.bottom > 0;
    if (open != _keyboardOpen) setState(() => _keyboardOpen = open);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_keyboardOpen) return const SizedBox.shrink();
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
          widget.label,
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
