import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Botão redondo por cima do PDF para trocar de modelo (esquerda/direita).
class PdfModelSelectArrow extends StatelessWidget {
  const PdfModelSelectArrow({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: buttonColor,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: blackColor, size: 26),
        ),
      ),
    );
  }
}
