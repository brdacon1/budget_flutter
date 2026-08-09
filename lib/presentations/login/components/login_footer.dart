import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/presentations/singup/singup_view.dart';

/// Rodapé do login com o atalho de cadastro.
///
/// O cadastro agora é um **bottom modal** (`showSingUpBottomModal`) no padrão
/// do app — não mais uma tela cheia empilhada. Ao fechar o modal, dispara
/// `onRegisterClosed` para que o login recarregue seu estado.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key, required this.onRegisterClosed});

  final VoidCallback onRegisterClosed;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: bgColor,
      elevation: 0,
      child: Container(
        height: 65.0,
        color: bgColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Quer se cadastrar? ',
              style: GoogleFonts.heebo(
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                showSingUpBottomModal(context)
                    .then((_) => onRegisterClosed());
              },
              child: Text(
                'Clique aqui',
                style: GoogleFonts.heebo(
                  color: buttonColor.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
