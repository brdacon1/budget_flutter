import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Moldura das telas abertas pela Home (lista de orçamentos, dashboard):
/// barra com o botão voltar por cima da tela original, que não muda.
class HomeSubPage extends StatelessWidget {
  const HomeSubPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: child,
    );
  }
}
