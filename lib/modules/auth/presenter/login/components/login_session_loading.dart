import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Tela cheia exibida enquanto a sessão salva é verificada na abertura.
/// Não tem nenhum botão: impede interação até decidir entre entrar
/// direto ou mostrar o login.
class LoginSessionLoading extends StatelessWidget {
  const LoginSessionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: secondaryColor,
      body: Center(child: CircularProgressIndicator(color: Color(0xFF0DF5E4))),
    );
  }
}
