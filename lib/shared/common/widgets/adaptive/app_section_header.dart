import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cabeçalho de tela padrão (voltar + título Heebo 26 bold), sem tamanhos por
/// fração da tela. Substitui `AppHeader`/`AppHeaderSecondTitle` nas telas
/// migradas (DESIGN_SYSTEM §3, §8.7).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        defaultPadding,
        defaultPadding,
        defaultPadding,
        defaultPadding,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_outlined,
                color: whiteColor,
                size: 32,
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.heebo(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 1,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
