import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Base visual reutilizável para os bottom modals do app.
///
/// O conteúdo é exibido num [showModalBottomSheet] com:
/// - fundo branco (`Colors.white`);
/// - header com título (cinza máximo) + botão fechar (cinza);
/// - padding automático de `viewInsets` para acompanhar o teclado;
/// - botão de ação padrão (estilo `buttonColor`, cantos arredondados) no rodapé,
///   com texto cinza máximo.
///
/// Component `Stateless` puro — recebe o conteúdo por parâmetro. As regras de
/// negócio continuam em quem chama (ViewModel/Service), que decide o momento
/// de fechar o modal (`Navigator.pop`) e de atualizar a tela de origem.
class AppBottomModal extends StatelessWidget {
  const AppBottomModal({
    super.key,
    required this.title,
    required this.child,
    required this.buttonLabel,
    required this.onButtonPressed,
    this.buttonVisible = true,
  });

  final String title;
  final Widget child;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final bool buttonVisible;

  /// Cor cinza "máxima" usada em todos os textos do modal.
  static const Color grayColor = Color(0xFF424242);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Acompanha o teclado: ao abrir o campo, o conteúdo sobe junto.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DragHandle(),
              _Header(title: title),
              const Divider(color: Color(0xFFE0E0E0), thickness: 1),
              Flexible(fit: FlexFit.loose, child: child),
              if (buttonVisible) ...[
                const SizedBox(height: 16),
                _ModalButton(label: buttonLabel, onPressed: onButtonPressed),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFBDBDBD),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.heebo(
              color: AppBottomModal.grayColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppBottomModal.grayColor, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ModalButton extends StatelessWidget {
  const _ModalButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF0DF5E4), // buttonColor padrão
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.heebo(
          color: AppBottomModal.grayColor,
          letterSpacing: 0.5,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Helper que abre um [AppBottomModal] como modal bottom sheet.
Future<void> showAppBottomModal(
  BuildContext context, {
  required String title,
  required Widget child,
  required String buttonLabel,
  required VoidCallback onButtonPressed,
  bool buttonVisible = true,
  bool isScrollControlled = true,
  bool dismissible = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    builder: (context) => AppBottomModal(
      title: title,
      child: child,
      buttonLabel: buttonLabel,
      onButtonPressed: onButtonPressed,
      buttonVisible: buttonVisible,
    ),
  );
}
