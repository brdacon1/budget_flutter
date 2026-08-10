import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/constants.dart';

/// Botão de salvar/atualizar do formulário de recibo.
///
/// Component `Stateless` puro — recebe o rótulo e o callback. Não acessa
/// services nem o ViewModel. Mantém o estilo original (cantos arredondados,
/// `buttonColor`, texto preto bold).
class ReceiptCreatorSaveButton extends StatelessWidget {
  const ReceiptCreatorSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 20),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: buttonColor,
          padding:
              const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.heebo(
            color: Colors.black,
            letterSpacing: 0.5,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
