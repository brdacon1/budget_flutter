import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal inferior de confirmação (Sim/Não).
///
/// Substitui os antigos `AwesomeDialog` com botões "Sim"/"Não". Fundo branco,
/// textos cinza máximo, dois botões no rodapé (Cancelar / Confirmar) no padrão
/// dos botões do projeto. Retorna `true` ao confirmar e `false` ao cancelar.
class ConfirmBottomModalWidget extends StatelessWidget {
  const ConfirmBottomModalWidget({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Sim',
    this.cancelLabel = 'Não',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Row(
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
                  icon: const Icon(
                    Icons.close,
                    color: AppBottomModal.grayColor,
                    size: 26,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE0E0E0), thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                message,
                style: GoogleFonts.heebo(
                  color: AppBottomModal.grayColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Button(
                    label: cancelLabel,
                    outlined: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Button(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: outlined ? Colors.white : const Color(0xFF0DF5E4),
        foregroundColor: AppBottomModal.grayColor,
        side: outlined
            ? const BorderSide(color: Color(0xFF9E9E9E), width: 2)
            : null,
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.heebo(
          color: AppBottomModal.grayColor,
          letterSpacing: 0.5,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Helper que abre o [ConfirmBottomModalWidget] e retorna `true`/`false`.
Future<bool> showConfirmBottomModal(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Sim',
  String cancelLabel = 'Não',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ConfirmBottomModalWidget(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}
